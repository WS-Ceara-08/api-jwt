#!/bin/bash

# =============================================================================
# Script de Testes Automatizados - SafeEdu API
# WorldSkills 2025 - Módulo A2
# =============================================================================

set -e  # Sair em caso de erro

# =============================================================================
# CONFIGURAÇÕES E CORES
# =============================================================================

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Configurações de teste
BASE_URL="${1:-http://localhost:8080}"
TIMEOUT=10
VERBOSE=false

# Contadores de teste
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "=============================================="
    echo "🧪 SafeEdu API - Testes Automatizados"
    echo "🌐 Base URL: $BASE_URL"
    echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=============================================="
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
    ((TOTAL_TESTS++))
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
}

print_failure() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# Função para fazer requisições HTTP
make_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local headers="$4"
    local expected_status="${5:-200}"
    
    local url="${BASE_URL}${endpoint}"
    local curl_opts=("-s" "-w" "%{http_code}" "--max-time" "$TIMEOUT")
    
    if [ -n "$headers" ]; then
        while IFS= read -r header; do
            curl_opts+=("-H" "$header")
        done <<< "$headers"
    fi
    
    if [ -n "$data" ]; then
        curl_opts+=("-d" "$data")
    fi
    
    local response
    response=$(curl "${curl_opts[@]}" -X "$method" "$url" 2>/dev/null || echo "ERROR")
    
    if [ "$response" = "ERROR" ]; then
        echo "HTTP_ERROR"
        return 1
    fi
    
    # Extrair status code (últimos 3 caracteres)
    local status_code="${response: -3}"
    local body="${response%???}"
    
    print_debug "Status: $status_code, Body: ${body:0:100}..."
    
    # Verificar status code esperado
    if [ "$status_code" != "$expected_status" ]; then
        echo "STATUS_ERROR:$status_code"
        return 1
    fi
    
    echo "$body"
    return 0
}

# Função para extrair valor JSON (simples, sem jq dependency)
extract_json_value() {
    local json="$1"
    local key="$2"
    
    # Método simples para extrair valor sem jq
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | cut -d'"' -f4
}

# Função para verificar se API está rodando
check_api_availability() {
    print_section "Verificação de Conectividade"
    
    print_test "Verificando se API está rodando..."
    
    local health_response
    health_response=$(make_request "GET" "/health" "" "" "200")
    
    if [[ "$health_response" == *"ERROR"* ]]; then
        print_failure "API não está rodando em $BASE_URL"
        print_info "💡 Para testar localmente: dart run bin/server.dart"
        print_info "💡 Para testar produção: $0 https://safeedu-api.fly.dev"
        exit 1
    else
        print_success "API está respondendo"
        if command -v jq >/dev/null 2>&1; then
            echo "$health_response" | jq '.' 2>/dev/null || echo "$health_response"
        else
            echo "$health_response"
        fi
    fi
}

# =============================================================================
# TESTES DOS ENDPOINTS
# =============================================================================

test_health_check() {
    print_section "Health Check"
    
    print_test "GET /health"
    local response
    response=$(make_request "GET" "/health" "" "" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Health check falhou"
        return 1
    fi
    
    if [[ "$response" == *"healthy"* ]]; then
        print_success "Health check passou"
    else
        print_failure "Health check retornou resposta inesperada"
        return 1
    fi
}

test_motd() {
    print_section "Message of the Day (MOTD)"
    
    print_test "GET /A2/motd"
    local response
    response=$(make_request "GET" "/A2/motd" "" "" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "MOTD endpoint falhou"
        return 1
    fi
    
    if [[ "$response" == *"message"* ]] && [[ "$response" == *"SafeEdu"* ]]; then
        print_success "MOTD endpoint funcionando"
        local message
        message=$(extract_json_value "$response" "message")
        print_info "Mensagem: $message"
    else
        print_failure "MOTD retornou resposta inesperada"
        return 1
    fi
}

test_authentication() {
    print_section "Autenticação JWT"
    
    # Teste 1: Login com credenciais válidas
    print_test "POST /jwt/generate_token (credenciais válidas)"
    local login_data='{"email": "fred@fred.com", "password": "123"}'
    local headers="Content-Type: application/json"
    
    local login_response
    login_response=$(make_request "POST" "/jwt/generate_token" "$login_data" "$headers" "200")
    
    if [[ "$login_response" == *"ERROR"* ]]; then
        print_failure "Login falhou"
        return 1
    fi
    
    if [[ "$login_response" == *"token"* ]] && [[ "$login_response" == *"success"* ]]; then
        print_success "Login com credenciais válidas funcionando"
        
        # Extrair token para usar em outros testes
        JWT_TOKEN=$(extract_json_value "$login_response" "token")
        if [ -z "$JWT_TOKEN" ]; then
            # Método alternativo se o primeiro falhar
            JWT_TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        print_info "Token obtido: ${JWT_TOKEN:0:20}..."
    else
        print_failure "Login retornou resposta inesperada"
        return 1
    fi
    
    # Teste 2: Login com credenciais inválidas
    print_test "POST /jwt/generate_token (credenciais inválidas)"
    local invalid_login='{"email": "fred@fred.com", "password": "senha_errada"}'
    
    local invalid_response
    invalid_response=$(make_request "POST" "/jwt/generate_token" "$invalid_login" "$headers" "401")
    
    if [[ "$invalid_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Login com credenciais inválidas deveria retornar 401"
        return 1
    else
        print_success "Login com credenciais inválidas rejeitado corretamente"
    fi
    
    # Teste 3: Validar token
    if [ -n "$JWT_TOKEN" ]; then
        print_test "POST /jwt/validate_token"
        local validate_data="{\"token\": \"$JWT_TOKEN\"}"
        
        local validate_response
        validate_response=$(make_request "POST" "/jwt/validate_token" "$validate_data" "$headers" "200")
        
        if [[ "$validate_response" == *"valid"* ]] && [[ "$validate_response" == *"true"* ]]; then
            print_success "Validação de token funcionando"
        else
            print_failure "Validação de token falhou"
            return 1
        fi
    fi
}

test_school_list() {
    print_section "Lista de Escolas"
    
    if [ -z "$JWT_TOKEN" ]; then
        print_failure "Token JWT necessário para este teste"
        return 1
    fi
    
    print_test "GET /A2/school_list (com autenticação)"
    local auth_header="Authorization: Bearer $JWT_TOKEN"
    
    local response
    response=$(make_request "GET" "/A2/school_list" "" "$auth_header" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Lista de escolas falhou"
        return 1
    fi
    
    if [[ "$response" == *"schools"* ]] && [[ "$response" == *"Escola A"* ]]; then
        print_success "Lista de escolas funcionando"
        
        # Contar escolas (método simples)
        local school_count
        school_count=$(echo "$response" | grep -o '"name"' | wc -l)
        print_info "Escolas encontradas: $school_count"
    else
        print_failure "Lista de escolas retornou resposta inesperada"
        return 1
    fi
    
    # Teste sem autenticação
    print_test "GET /A2/school_list (sem autenticação)"
    local unauth_response
    unauth_response=$(make_request "GET" "/A2/school_list" "" "" "401")
    
    if [[ "$unauth_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Endpoint deveria retornar 401 sem autenticação"
        return 1
    else
        print_success "Proteção de autenticação funcionando"
    fi
}

test_comments() {
    print_section "Sistema de Comentários"
    
    if [ -z "$JWT_TOKEN" ]; then
        print_failure "Token JWT necessário para este teste"
        return 1
    fi
    
    local auth_header="Authorization: Bearer $JWT_TOKEN"
    local content_header="Content-Type: application/json"
    local headers="$auth_header"$'\n'"$content_header"
    
    # Teste 1: Listar comentários
    print_test "GET /A2/comments"
    local response
    response=$(make_request "GET" "/A2/comments" "" "$auth_header" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Listagem de comentários falhou"
        return 1
    fi
    
    if [[ "$response" == *"comments"* ]]; then
        print_success "Listagem de comentários funcionando"
        
        local comment_count
        comment_count=$(echo "$response" | grep -o '"comment"' | wc -l)
        print_info "Comentários encontrados: $comment_count"
    else
        print_failure "Listagem de comentários retornou resposta inesperada"
        return 1
    fi
    
    # Teste 2: Adicionar comentário
    print_test "POST /A2/comments (adicionar comentário)"
    local comment_data='{"id_escola": "1", "comentario": "Comentário de teste automatizado - '$(date +%s)'"}'
    
    local add_response
    add_response=$(make_request "POST" "/A2/comments" "$comment_data" "$headers" "200")
    
    if [[ "$add_response" == *"ERROR"* ]]; then
        print_failure "Adição de comentário falhou"
        return 1
    fi
    
    if [[ "$add_response" == *"success"* ]] && [[ "$add_response" == *"Comentário adicionado"* ]]; then
        print_success "Adição de comentário funcionando"
    else
        print_failure "Adição de comentário retornou resposta inesperada"
        return 1
    fi
    
    # Teste 3: Comentário inválido
    print_test "POST /A2/comments (dados inválidos)"
    local invalid_comment='{"comentario": ""}'
    
    local invalid_response
    invalid_response=$(make_request "POST" "/A2/comments" "$invalid_comment" "$headers" "400")
    
    if [[ "$invalid_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Comentário inválido deveria retornar 400"
        return 1
    else
        print_success "Validação de comentários funcionando"
    fi
}

test_prints() {
    print_section "Sistema de Prints"
    
    if [ -z "$JWT_TOKEN" ]; then
        print_failure "Token JWT necessário para este teste"
        return 1
    fi
    
    local auth_header="Authorization: Bearer $JWT_TOKEN"
    
    # Teste 1: Listar prints
    print_test "GET /A2/prints"
    local response
    response=$(make_request "GET" "/A2/prints" "" "$auth_header" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Listagem de prints falhou"
        return 1
    fi
    
    if [[ "$response" == *"prints"* ]]; then
        print_success "Listagem de prints funcionando"
        
        local print_count
        print_count=$(echo "$response" | grep -o '"file_name"' | wc -l)
        print_info "Prints encontrados: $print_count"
    else
        print_failure "Listagem de prints retornou resposta inesperada"
        return 1
    fi
    
    # Teste 2: Upload de print (criar arquivo temporário)
    print_test "POST /A2/prints (upload de arquivo)"
    
    # Criar imagem de teste (1x1 pixel PNG)
    local test_image="/tmp/test_image_$$.png"
    echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$test_image" 2>/dev/null || {
        # Fallback: criar arquivo de texto simples
        echo "test image data" > "$test_image"
    }
    
    # Upload usando curl diretamente (multipart é complexo para nossa função)
    local upload_response
    upload_response=$(curl -s -w "%{http_code}" --max-time "$TIMEOUT" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -F "id_user=1" \
        -F "imagem=@$test_image" \
        "${BASE_URL}/A2/prints" 2>/dev/null || echo "ERROR")
    
    # Limpar arquivo temporário
    rm -f "$test_image"
    
    if [ "$upload_response" = "ERROR" ]; then
        print_failure "Upload de print falhou (conexão)"
        return 1
    fi
    
    local status_code="${upload_response: -3}"
    local body="${upload_response%???}"
    
    if [ "$status_code" = "200" ] && [[ "$body" == *"success"* ]]; then
        print_success "Upload de print funcionando"
    else
        print_failure "Upload de print falhou (status: $status_code)"
        return 1
    fi
}

test_error_handling() {
    print_section "Tratamento de Erros"
    
    # Teste 1: Endpoint inexistente
    print_test "GET /endpoint/inexistente"
    local response
    response=$(make_request "GET" "/endpoint/inexistente" "" "" "404")
    
    if [[ "$response" == *"STATUS_ERROR"* ]]; then
        print_failure "Endpoint inexistente deveria retornar 404"
        return 1
    else
        print_success "Tratamento de 404 funcionando"
    fi
    
    # Teste 2: Token inválido
    print_test "GET /A2/school_list (token inválido)"
    local invalid_header="Authorization: Bearer token_invalido_123"
    
    local invalid_response
    invalid_response=$(make_request "GET" "/A2/school_list" "" "$invalid_header" "401")
    
    if [[ "$invalid_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Token inválido deveria retornar 401"
        return 1
    else
        print_success "Validação de token funcionando"
    fi
}

test_second_user() {
    print_section "Teste com Segundo Usuário"
    
    # Login com segundo usuário
    print_test "Login com julia@safeedu.com"
    local julia_login='{"email": "julia@safeedu.com", "password": "123456"}'
    local headers="Content-Type: application/json"
    
    local julia_response
    julia_response=$(make_request "POST" "/jwt/generate_token" "$julia_login" "$headers" "200")
    
    if [[ "$julia_response" == *"ERROR"* ]]; then
        print_failure "Login da Júlia falhou"
        return 1
    fi
    
    if [[ "$julia_response" == *"token"* ]] && [[ "$julia_response" == *"Júlia"* ]]; then
        print_success "Login da Júlia funcionando"
        
        local julia_token
        julia_token=$(extract_json_value "$julia_response" "token")
        if [ -z "$julia_token" ]; then
            julia_token=$(echo "$julia_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        
        # Testar endpoint com token da Júlia
        print_test "Acesso aos dados com token da Júlia"
        local auth_header="Authorization: Bearer $julia_token"
        
        local schools_response
        schools_response=$(make_request "GET" "/A2/school_list" "" "$auth_header" "200")
        
        if [[ "$schools_response" == *"schools"* ]]; then
            print_success "Múltiplos usuários funcionando corretamente"
        else
            print_failure "Problemas com múltiplos usuários"
            return 1
        fi
    else
        print_failure "Login da Júlia retornou resposta inesperada"
        return 1
    fi
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_report() {
    echo ""
    echo -e "${CYAN}=============================================="
    echo "📊 Relatório de Testes"
    echo "=============================================="
    echo -e "${NC}"
    
    echo -e "${BLUE}Estatísticas:${NC}"
    echo "  Total de testes: $TOTAL_TESTS"
    echo -e "  ${GREEN}Passou: $PASSED_TESTS${NC}"
    echo -e "  ${RED}Falhou: $FAILED_TESTS${NC}"
    
    local success_rate
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "  Taxa de sucesso: $success_rate%"
    fi
    
    echo ""
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 Todos os testes passaram!${NC}"
        echo -e "${GREEN}✅ API SafeEdu está funcionando perfeitamente${NC}"
    else
        echo -e "${RED}❌ $FAILED_TESTS teste(s) falharam${NC}"
        echo -e "${YELLOW}⚠️  Verifique os logs acima para detalhes${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔗 Endpoints testados:${NC}"
    echo "  GET  $BASE_URL/health"
    echo "  GET  $BASE_URL/A2/motd"
    echo "  POST $BASE_URL/jwt/generate_token"
    echo "  POST $BASE_URL/jwt/validate_token"
    echo "  GET  $BASE_URL/A2/school_list"
    echo "  GET  $BASE_URL/A2/comments"
    echo "  POST $BASE_URL/A2/comments"
    echo "  GET  $BASE_URL/A2/prints"
    echo "  POST $BASE_URL/A2/prints"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                echo "Uso: $0 [BASE_URL] [-v|--verbose] [-h|--help]"
                echo ""
                echo "Argumentos:"
                echo "  BASE_URL     URL base da API (padrão: http://localhost:8080)"
                echo "  -v, --verbose    Mostrar informações detalhadas"
                echo "  -h, --help       Mostrar esta ajuda"
                echo ""
                echo "Exemplos:"
                echo "  $0                                    # Testar local"
                echo "  $0 https://safeedu-api.fly.dev       # Testar produção"
                echo "  $0 -v                                 # Modo verbose"
                exit 0
                ;;
            *)
                BASE_URL="$1"
                shift
                ;;
        esac
    done
    
    # Banner
    print_banner
    
    # Verificar disponibilidade
    check_api_availability
    
    # Executar testes
    test_health_check
    test_motd
    test_authentication
    test_school_list
    test_comments
    test_prints
    test_error_handling
    test_second_user
    
    # Relatório final
    generate_report
    
    # Exit code baseado nos resultados
    if [ "$FAILED_TESTS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Verificar dependências
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} curl não encontrado. Instale curl para executar os testes."
    exit 1
fi

# Executar
main "$@"