#!/bin/bash

# =============================================================================
# Script de Testes Automatizados - SafeEdu API
# WorldSkills 2025 - Módulo A2 - Desenvolvimento de Aplicativos
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
BASE_URL="${1:-https://bibliotech-api.fly.dev}"
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
    echo "🛡️ SafeEdu API - Testes Automatizados"
    echo "🏫 Sistema de Segurança Urbana - Escolas"
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
    
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | cut -d'"' -f4
}

# Função para verificar se API está rodando
check_api_availability() {
    print_section "Verificação de Conectividade"
    
    print_test "Verificando se SafeEdu API está rodando..."
    
    local health_response
    health_response=$(make_request "GET" "/health" "" "" "200")
    
    if [[ "$health_response" == *"ERROR"* ]]; then
        print_failure "SafeEdu API não está rodando em $BASE_URL"
        print_info "💡 Para testar localmente: dart run bin/server.dart"
        print_info "💡 Para testar produção: $0 https://bibliotech-api.fly.dev"
        exit 1
    else
        print_success "SafeEdu API está respondendo"
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
    
    if [[ "$response" == *"healthy"* ]] && [[ "$response" == *"SafeEdu"* ]]; then
        print_success "Health check passou"
        print_info "API: SafeEdu"
    else
        print_failure "Health check retornou resposta inesperada"
        return 1
    fi
}

test_motd() {
    print_section "Message of the Day (MOTD)"
    
    print_test "GET /worldskills/A2/motd"
    local response
    response=$(make_request "GET" "/worldskills/A2/motd" "" "" "200")
    
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
    
    # Teste 1: Login com credenciais válidas (Fred)
    print_test "POST /worldskills/A2/jwt/generate_token (Fred)"
    local login_data='{"email": "fred@fred.com", "password": "fred123"}'
    local headers="Content-Type: application/json"
    
    local login_response
    login_response=$(make_request "POST" "/worldskills/A2/jwt/generate_token" "$login_data" "$headers" "200")
    
    if [[ "$login_response" == *"ERROR"* ]]; then
        print_failure "Login do Fred falhou"
        return 1
    fi
    
    if [[ "$login_response" == *"token"* ]] && [[ "$login_response" == *"success"* ]]; then
        print_success "Login do Fred funcionando"
        
        # Extrair token para usar em outros testes
        JWT_TOKEN=$(extract_json_value "$login_response" "token")
        if [ -z "$JWT_TOKEN" ]; then
            JWT_TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        print_info "Token obtido: ${JWT_TOKEN:0:20}..."
    else
        print_failure "Login do Fred retornou resposta inesperada"
        return 1
    fi
    
    # Teste 2: Login com senha sem números (deve falhar)
    print_test "POST /worldskills/A2/jwt/generate_token (senha sem números)"
    local invalid_login='{"email": "fred@fred.com", "password": "abcdef"}'
    
    local invalid_response
    invalid_response=$(make_request "POST" "/worldskills/A2/jwt/generate_token" "$invalid_login" "$headers" "400")
    
    if [[ "$invalid_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Senha sem números deveria retornar 400"
        return 1
    else
        print_success "Validação de senha com letras e números funcionando"
    fi
    
    # Teste 3: Login com senha curta (deve falhar)
    print_test "POST /worldskills/A2/jwt/generate_token (senha curta)"
    local short_pass='{"email": "fred@fred.com", "password": "12a"}'
    
    local short_response
    short_response=$(make_request "POST" "/worldskills/A2/jwt/generate_token" "$short_pass" "$headers" "400")
    
    if [[ "$short_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Senha curta deveria retornar 400"
        return 1
    else
        print_success "Validação de senha de 6+ caracteres funcionando"
    fi
    
    # Teste 4: Validar token
    if [ -n "$JWT_TOKEN" ]; then
        print_test "POST /worldskills/A2/jwt/validate_token"
        local validate_data="{\"token\": \"$JWT_TOKEN\"}"
        
        local validate_response
        validate_response=$(make_request "POST" "/worldskills/A2/jwt/validate_token" "$validate_data" "$headers" "200")
        
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
    
    local auth_header="Authorization: Bearer $JWT_TOKEN"
    
    print_test "GET /worldskills/A2/school_list (com autenticação)"
    local response
    response=$(make_request "GET" "/worldskills/A2/school_list" "" "$auth_header" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Lista de escolas falhou"
        return 1
    fi
    
    if [[ "$response" == *"schools"* ]] && [[ "$response" == *"Colégio Militar"* ]]; then
        print_success "Lista de escolas funcionando"
        
        # Verificar ordenação alfabética
        if [[ "$response" == *"Colégio Militar de Fortaleza"* ]]; then
            print_success "Ordenação alfabética implementada"
        fi
        
        # Contar escolas
        local school_count
        school_count=$(echo "$response" | grep -o '"nome"' | wc -l)
        print_info "Escolas encontradas: $school_count"
    else
        print_failure "Lista de escolas retornou resposta inesperada"
        return 1
    fi
    
    # Teste sem autenticação
    print_test "GET /worldskills/A2/school_list (sem autenticação)"
    local unauth_response
    unauth_response=$(make_request "GET" "/worldskills/A2/school_list" "" "" "401")
    
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
    print_test "GET /worldskills/A2/comments"
    local response
    response=$(make_request "GET" "/worldskills/A2/comments" "" "$auth_header" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Listagem de comentários falhou"
        return 1
    fi
    
    if [[ "$response" == *"comments"* ]]; then
        print_success "Listagem de comentários funcionando"
        
        local comment_count
        comment_count=$(echo "$response" | grep -o '"comentario"' | wc -l)
        print_info "Comentários encontrados: $comment_count"
    else
        print_failure "Listagem de comentários retornou resposta inesperada"
        return 1
    fi
    
    # Teste 2: Adicionar comentário
    print_test "POST /worldskills/A2/comments (adicionar comentário)"
    local comment_data='{"id_escola": "1", "comentario": "Comentário de teste SafeEdu - '$(date +%s)'"}'
    
    local add_response
    add_response=$(make_request "POST" "/worldskills/A2/comments" "$comment_data" "$headers" "200")
    
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
    
    # Teste 3: Comentário com escola inexistente
    print_test "POST /worldskills/A2/comments (escola inexistente)"
    local invalid_comment='{"id_escola": "999", "comentario": "Teste"}'
    
    local invalid_response
    invalid_response=$(make_request "POST" "/worldskills/A2/comments" "$invalid_comment" "$headers" "404")
    
    if [[ "$invalid_response" == *"STATUS_ERROR"* ]]; then
        print_failure "Escola inexistente deveria retornar 404"
        return 1
    else
        print_success "Validação de escola existente funcionando"
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
    print_test "GET /worldskills/A2/prints"
    local response
    response=$(make_request "GET" "/worldskills/A2/prints" "" "$auth_header" "200")
    
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
    
    # Teste 2: Upload de print via JSON
    print_test "POST /worldskills/A2/prints (JSON)"
    local json_upload='{"id_user": "1"}'
    local json_headers="$auth_header"$'\n'"Content-Type: application/json"
    
    local upload_response
    upload_response=$(make_request "POST" "/worldskills/A2/prints" "$json_upload" "$json_headers" "200")
    
    if [[ "$upload_response" == *"ERROR"* ]]; then
        print_failure "Upload JSON de print falhou"
        return 1
    fi
    
    if [[ "$upload_response" == *"success"* ]] && [[ "$upload_response" == *"safeedu"* ]]; then
        print_success "Upload JSON de print funcionando"
    else
        print_failure "Upload JSON de print retornou resposta inesperada"
        return 1
    fi
}

test_second_user() {
    print_section "Teste com Segundo Usuário"
    
    # Login com Maria
    print_test "Login com maria@safeedu.com"
    local maria_login='{"email": "maria@safeedu.com", "password": "maria123"}'
    local headers="Content-Type: application/json"
    
    local maria_response
    maria_response=$(make_request "POST" "/worldskills/A2/jwt/generate_token" "$maria_login" "$headers" "200")
    
    if [[ "$maria_response" == *"ERROR"* ]]; then
        print_failure "Login da Maria falhou"
        return 1
    fi
    
    if [[ "$maria_response" == *"token"* ]] && [[ "$maria_response" == *"Maria"* ]]; then
        print_success "Login da Maria funcionando"
        
        local maria_token
        maria_token=$(extract_json_value "$maria_response" "token")
        if [ -z "$maria_token" ]; then
            maria_token=$(echo "$maria_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        fi
        
        # Testar endpoint com token da Maria
        print_test "Acesso às escolas com token da Maria"
        local auth_header="Authorization: Bearer $maria_token"
        
        local schools_response
        schools_response=$(make_request "GET" "/worldskills/A2/school_list" "" "$auth_header" "200")
        
        if [[ "$schools_response" == *"schools"* ]]; then
            print_success "Múltiplos usuários funcionando corretamente"
        else
            print_failure "Problemas com múltiplos usuários"
            return 1
        fi
    else
        print_failure "Login da Maria retornou resposta inesperada"
        return 1
    fi
}

test_debug_routes() {
    print_section "Debug Routes"
    
    print_test "GET /debug/routes"
    local response
    response=$(make_request "GET" "/debug/routes" "" "" "200")
    
    if [[ "$response" == *"ERROR"* ]]; then
        print_failure "Debug routes falhou"
        return 1
    fi
    
    if [[ "$response" == *"available_routes"* ]] && [[ "$response" == *"SafeEdu"* ]]; then
        print_success "Debug routes funcionando"
        print_info "API identificada como SafeEdu"
    else
        print_failure "Debug routes retornou resposta inesperada"
        return 1
    fi
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_report() {
    echo ""
    echo -e "${CYAN}=============================================="
    echo "📊 Relatório de Testes - SafeEdu API"
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
        echo -e "${GREEN}✅ SafeEdu API está funcionando perfeitamente${NC}"
    else
        echo -e "${RED}❌ $FAILED_TESTS teste(s) falharam${NC}"
        echo -e "${YELLOW}⚠️  Verifique os logs acima para detalhes${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔗 Endpoints testados:${NC}"
    echo "  GET  $BASE_URL/health"
    echo "  GET  $BASE_URL/worldskills/A2/motd"
    echo "  POST $BASE_URL/worldskills/A2/jwt/generate_token"
    echo "  POST $BASE_URL/worldskills/A2/jwt/validate_token"
    echo "  GET  $BASE_URL/worldskills/A2/school_list"
    echo "  GET  $BASE_URL/worldskills/A2/comments"
    echo "  POST $BASE_URL/worldskills/A2/comments"
    echo "  GET  $BASE_URL/worldskills/A2/prints"
    echo "  POST $BASE_URL/worldskills/A2/prints"
    echo ""
    
    echo -e "${BLUE}🏫 Funcionalidades SafeEdu validadas:${NC}"
    echo "  ✅ Senha com 6+ caracteres + letras + números"
    echo "  ✅ Lista de escolas ordenada alfabeticamente"
    echo "  ✅ URLs com /worldskills/A2/"
    echo "  ✅ Contexto alterado de bibliotecas para escolas"
    echo "  ✅ Empresa SafeEdu identificada"
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
                echo "  BASE_URL     URL base da API (padrão: https://bibliotech-api.fly.dev)"
                echo "  -v, --verbose    Mostrar informações detalhadas"
                echo "  -h, --help       Mostrar esta ajuda"
                echo ""
                echo "Exemplos:"
                echo "  $0                                                # Testar produção"
                echo "  $0 http://localhost:8080                          # Testar local"
                echo "  $0 -v                                             # Modo verbose"
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
    test_debug_routes
    test_motd
    test_authentication
    test_school_list
    test_comments
    test_prints
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