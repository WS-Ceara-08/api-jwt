#!/bin/bash

# =============================================================================
# Script de Deploy Automatizado - SafeEdu API
# WorldSkills 2025 - Módulo A2
# =============================================================================

set -e  # Sair em caso de erro
set -u  # Sair se variável não definida

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

# Configurações do projeto
readonly APP_NAME="safeedu-api"
readonly REGION="gru"
readonly VOLUME_NAME="safeedu_uploads"
readonly VOLUME_SIZE="1"

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "=============================================="
    echo "🚀 SafeEdu API - Deploy Automatizado"
    echo "🌐 Destino: Fly.io"
    echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=============================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para aguardar input do usuário
wait_for_input() {
    local message="$1"
    local default="${2:-}"
    local response
    
    if [ -n "$default" ]; then
        read -p "$message [$default]: " response
        response="${response:-$default}"
    else
        read -p "$message: " response
    fi
    
    echo "$response"
}

# Função para confirmar ação
confirm_action() {
    local message="$1"
    local response
    
    read -p "$message (y/N): " -n 1 -r response
    echo
    [[ $response =~ ^[Yy]$ ]]
}

# =============================================================================
# VERIFICAÇÕES PRÉ-DEPLOY
# =============================================================================

check_prerequisites() {
    print_step "Verificando pré-requisitos..."
    
    # Verificar se flyctl está instalado
    if ! command_exists fly; then
        print_error "Fly CLI não encontrado!"
        print_info "Instale em: https://fly.io/docs/flyctl/installing/"
        print_info "macOS: brew install flyctl"
        print_info "Linux: curl -L https://fly.io/install.sh | sh"
        exit 1
    fi
    
    # Verificar versão do flyctl
    local fly_version
    fly_version=$(fly version | head -n1 | awk '{print $3}' || echo "unknown")
    print_info "Fly CLI version: $fly_version"
    
    # Verificar se está logado
    if ! fly auth whoami >/dev/null 2>&1; then
        print_warning "Você não está logado no Fly.io"
        print_step "Fazendo login..."
        fly auth login
    fi
    
    local user
    user=$(fly auth whoami 2>/dev/null || echo "unknown")
    print_success "Logado como: $user"
    
    # Verificar se Docker está instalado (opcional)
    if command_exists docker; then
        local docker_version
        docker_version=$(docker --version | awk '{print $3}' | sed 's/,//' || echo "unknown")
        print_info "Docker version: $docker_version"
    else
        print_warning "Docker não encontrado (opcional para builds locais)"
    fi
}

check_project_files() {
    print_step "Verificando arquivos do projeto..."
    
    local required_files=(
        "bin/server.dart"
        "pubspec.yaml"
        "Dockerfile"
        "config/fly.toml"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Arquivos obrigatórios não encontrados:"
        for file in "${missing_files[@]}"; do
            echo "  ❌ $file"
        done
        exit 1
    fi
    
    print_success "Todos os arquivos necessários encontrados"
    
    # Verificar se pubspec.yaml está válido
    if ! dart pub deps >/dev/null 2>&1; then
        print_warning "Executando 'dart pub get' para resolver dependências..."
        dart pub get
    fi
}

# =============================================================================
# FUNÇÕES DE DEPLOY
# =============================================================================

check_app_exists() {
    print_step "Verificando se aplicação '$APP_NAME' existe..."
    
    if fly apps list 2>/dev/null | grep -q "^$APP_NAME"; then
        print_success "Aplicação '$APP_NAME' já existe"
        return 0
    else
        print_info "Aplicação '$APP_NAME' não existe - será criada"
        return 1
    fi
}

create_or_check_volume() {
    print_step "Verificando volume para uploads..."
    
    local volume_exists=false
    
    # Verificar se volume já existe
    if fly volumes list -a "$APP_NAME" 2>/dev/null | grep -q "$VOLUME_NAME"; then
        print_success "Volume '$VOLUME_NAME' já existe"
        volume_exists=true
    else
        print_step "Criando volume '$VOLUME_NAME'..."
        
        if fly volumes create "$VOLUME_NAME" --region "$REGION" --size "$VOLUME_SIZE" -a "$APP_NAME"; then
            print_success "Volume criado com sucesso"
        else
            print_error "Falha ao criar volume"
            exit 1
        fi
    fi
    
    # Mostrar informações do volume
    print_info "Informações do volume:"
    fly volumes list -a "$APP_NAME" | grep "$VOLUME_NAME" || true
}

configure_secrets() {
    print_step "Configurando secrets..."
    
    # Verificar se JWT_SECRET já existe
    if fly secrets list -a "$APP_NAME" 2>/dev/null | grep -q "JWT_SECRET"; then
        print_success "JWT_SECRET já configurado"
        
        if confirm_action "Deseja atualizar o JWT_SECRET?"; then
            local jwt_secret
            jwt_secret="safeedu_secret_key_$(date +%s)_$(openssl rand -hex 8)"
            
            print_step "Atualizando JWT_SECRET..."
            fly secrets set JWT_SECRET="$jwt_secret" -a "$APP_NAME"
            print_success "JWT_SECRET atualizado"
        fi
    else
        print_step "Configurando JWT_SECRET..."
        local jwt_secret
        jwt_secret="safeedu_secret_key_$(date +%s)_$(openssl rand -hex 8)"
        
        fly secrets set JWT_SECRET="$jwt_secret" -a "$APP_NAME"
        print_success "JWT_SECRET configurado"
    fi
    
    # Configurar outros secrets se necessário
    local additional_secrets=(
        "API_VERSION=1.0.0"
        "DEPLOY_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    )
    
    for secret in "${additional_secrets[@]}"; do
        local key="${secret%%=*}"
        local value="${secret#*=}"
        
        if ! fly secrets list -a "$APP_NAME" 2>/dev/null | grep -q "$key"; then
            print_step "Configurando $key..."
            fly secrets set "$key=$value" -a "$APP_NAME"
        fi
    done
}

perform_deploy() {
    local deploy_type="$1"
    
    print_step "Iniciando deploy ($deploy_type)..."
    echo ""
    
    if [ "$deploy_type" = "inicial" ]; then
        # Deploy inicial com launch
        print_step "Criando aplicação e fazendo deploy inicial..."
        
        # Copiar fly.toml para raiz se estiver em config/
        if [ -f "config/fly.toml" ] && [ ! -f "fly.toml" ]; then
            cp config/fly.toml fly.toml
            print_info "fly.toml copiado para raiz do projeto"
        fi
        
        # Launch com configurações específicas
        fly launch \
            --name "$APP_NAME" \
            --region "$REGION" \
            --no-deploy \
            --copy-config \
            --ha=false
        
        # Fazer deploy após configurar tudo
        fly deploy -a "$APP_NAME"
    else
        # Deploy de atualização
        print_step "Fazendo deploy de atualização..."
        fly deploy -a "$APP_NAME"
    fi
}

# =============================================================================
# VERIFICAÇÕES PÓS-DEPLOY
# =============================================================================

verify_deployment() {
    print_step "Verificando deploy..."
    
    # Aguardar um pouco para a aplicação inicializar
    print_info "Aguardando inicialização da aplicação..."
    sleep 15
    
    # Verificar status
    print_step "Verificando status da aplicação..."
    if fly status -a "$APP_NAME" | grep -q "running"; then
        print_success "Aplicação está rodando!"
    else
        print_warning "Aplicação pode estar iniciando ainda..."
        print_info "Logs recentes:"
        fly logs -a "$APP_NAME" --limit 10
    fi
    
    # Obter URL da aplicação
    local app_url="https://$APP_NAME.fly.dev"
    print_success "URL da aplicação: $app_url"
    
    # Testar endpoint de health
    print_step "Testando health check..."
    local health_check_passed=false
    
    for i in {1..5}; do
        if curl -f -s "$app_url/health" >/dev/null 2>&1; then
            print_success "Health check passou!"
            health_check_passed=true
            break
        else
            print_info "Tentativa $i/5 - aguardando..."
            sleep 10
        fi
    done
    
    if [ "$health_check_passed" = false ]; then
        print_warning "Health check falhou. Verificando logs..."
        fly logs -a "$APP_NAME" --limit 20
    fi
}

test_api_endpoints() {
    print_step "Testando endpoints da API..."
    
    local app_url="https://$APP_NAME.fly.dev"
    
    # Teste 1: MOTD (não requer autenticação)
    print_info "Testando endpoint MOTD..."
    if curl -f -s "$app_url/A2/motd" >/dev/null; then
        print_success "✅ MOTD endpoint funcionando"
    else
        print_warning "❌ MOTD endpoint com problemas"
    fi
    
    # Teste 2: Login
    print_info "Testando login..."
    local login_response
    login_response=$(curl -s -X POST "$app_url/jwt/generate_token" \
        -H "Content-Type: application/json" \
        -d '{"email": "fred@fred.com", "password": "123"}' || echo "FAIL")
    
    if echo "$login_response" | grep -q "token"; then
        print_success "✅ Sistema de login funcionando"
        
        # Extrair token para testes adicionais
        local token
        if command_exists jq; then
            token=$(echo "$login_response" | jq -r '.token' 2>/dev/null || echo "")
        else
            token=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4 || echo "")
        fi
        
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            # Teste 3: Endpoint autenticado
            print_info "Testando endpoint autenticado..."
            if curl -f -s -H "Authorization: Bearer $token" "$app_url/A2/school_list" >/dev/null; then
                print_success "✅ Endpoints autenticados funcionando"
            else
                print_warning "❌ Problemas com endpoints autenticados"
            fi
        fi
    else
        print_warning "❌ Problemas no sistema de login"
    fi
}

# =============================================================================
# INFORMAÇÕES FINAIS
# =============================================================================

show_final_info() {
    local app_url="https://$APP_NAME.fly.dev"
    
    echo ""
    echo -e "${CYAN}=============================================="
    echo "🎉 Deploy Concluído!"
    echo "=============================================="
    echo -e "${NC}"
    echo -e "${GREEN}📡 URL da API:${NC} $app_url"
    echo ""
    echo -e "${YELLOW}🧪 Endpoints para teste:${NC}"
    echo "   GET  $app_url/health"
    echo "   GET  $app_url/A2/motd"
    echo "   POST $app_url/jwt/generate_token"
    echo "   GET  $app_url/A2/school_list"
    echo "   GET  $app_url/A2/comments"
    echo ""
    echo -e "${YELLOW}👤 Usuários de teste:${NC}"
    echo "   fred@fred.com / 123"
    echo "   julia@safeedu.com / 123456"
    echo ""
    echo -e "${YELLOW}🔧 Comandos úteis:${NC}"
    echo "   fly logs -a $APP_NAME              # Ver logs"
    echo "   fly status -a $APP_NAME            # Status da app"
    echo "   fly ssh console -a $APP_NAME       # SSH no container"
    echo "   fly dashboard -a $APP_NAME         # Dashboard web"
    echo "   fly restart -a $APP_NAME           # Reiniciar app"
    echo ""
    echo -e "${YELLOW}📱 Configure seu app mobile:${NC}"
    echo "   Base URL: $app_url"
    echo ""
    echo -e "${GREEN}✅ API SafeEdu pronta para uso!${NC}"
    echo ""
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Banner inicial
    print_banner
    
    # Verificações pré-deploy
    check_prerequisites
    check_project_files
    
    # Verificar se app existe
    local deploy_type
    if check_app_exists; then
        deploy_type="atualização"
        print_info "Será feita uma atualização da aplicação existente"
    else
        deploy_type="inicial"
        print_info "Será criada uma nova aplicação"
    fi
    
    # Confirmar deploy
    echo ""
    if ! confirm_action "Deseja continuar com o deploy ($deploy_type)?"; then
        print_info "Deploy cancelado pelo usuário"
        exit 0
    fi
    
    # Executar deploy
    echo ""
    create_or_check_volume
    configure_secrets
    perform_deploy "$deploy_type"
    
    # Verificações pós-deploy
    verify_deployment
    test_api_endpoints
    
    # Informações finais
    show_final_info
    
    # Opção de abrir no navegador
    local app_url="https://$APP_NAME.fly.dev"
    if confirm_action "Deseja abrir a API no navegador?"; then
        if command_exists open; then
            open "$app_url/health"
        elif command_exists xdg-open; then
            xdg-open "$app_url/health"
        else
            print_info "Abra manualmente: $app_url/health"
        fi
    fi
    
    print_success "Script de deploy concluído!"
}

# =============================================================================
# TRATAMENTO DE ERROS
# =============================================================================

# Capturar erros e mostrar informações úteis
trap 'print_error "Script interrompido na linha $LINENO. Use fly logs -a $APP_NAME para debug."' ERR

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    print_error "Execute este script no diretório raiz do projeto SafeEdu API"
    print_info "Certifique-se de que pubspec.yaml está presente"
    exit 1
fi

# Executar função principal
main "$@"