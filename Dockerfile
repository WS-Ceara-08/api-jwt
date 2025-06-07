# Dockerfile otimizado para API SafeEdu
# WorldSkills 2025 - Módulo A2
# Multi-stage build para reduzir tamanho final

# =============================================================================
# STAGE 1: Build da aplicação
# =============================================================================
FROM dart:stable AS build

# Labels para metadados
LABEL maintainer="SafeEdu API Team"
LABEL version="1.0.0"
LABEL description="API SafeEdu para WorldSkills 2025"

# Definir variáveis de ambiente para build
ENV DART_SDK=/usr/lib/dart
ENV PATH="$DART_SDK/bin:$PATH"

# Criar diretório de trabalho
WORKDIR /app

# Copiar pubspec.yaml primeiro para aproveitar cache de layers do Docker
COPY pubspec.yaml ./

# Resolver dependências (esta layer será cached se pubspec.yaml não mudar)
RUN dart pub get

# Copiar todo o código fonte
COPY . .

# Verificar estrutura do projeto
RUN echo "=== Estrutura do projeto ===" && \
    find . -type f -name "*.dart" -o -name "*.yaml" | head -20

# Verificar se o arquivo principal existe
RUN test -f bin/server.dart || (echo "ERROR: bin/server.dart não encontrado!" && exit 1)

# Compilar aplicação para executável nativo otimizado
RUN dart compile exe bin/server.dart -o bin/server_compiled

# Verificar se compilação foi bem-sucedida
RUN test -f bin/server_compiled || (echo "ERROR: Compilação falhou!" && exit 1)

# =============================================================================
# STAGE 2: Imagem de produção mínima
# =============================================================================
FROM debian:bookworm-slim AS production

# Instalar dependências essenciais do sistema
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# Configurar timezone para Brasil
ENV TZ=America/Fortaleza
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Criar grupo e usuário para segurança (não-root)
RUN groupadd -r safeedu && \
    useradd -r -g safeedu -d /app -s /bin/false safeedu

# Definir diretório de trabalho
WORKDIR /app

# Copiar executável compilado do stage de build
COPY --from=build /app/bin/server_compiled /app/server

# Copiar arquivos de configuração necessários
COPY --from=build /app/pubspec.yaml /app/

# Criar estrutura de diretórios necessária
RUN mkdir -p /app/uploads /app/logs

# Configurar permissões corretas
RUN chown -R safeedu:safeedu /app && \
    chmod +x /app/server && \
    chmod 755 /app/uploads && \
    chmod 755 /app/logs

# Criar arquivo de configuração de logs
RUN echo "logs_directory=/app/logs" > /app/config.txt

# Mudar para usuário não-root (segurança)
USER safeedu

# Expor porta da aplicação
EXPOSE 8080

# Definir variáveis de ambiente para produção
ENV PORT=8080
ENV HOST=0.0.0.0
ENV ENVIRONMENT=production
ENV JWT_SECRET=safeedu_secret_key_2025
ENV LOG_LEVEL=info

# Health check para monitoramento
HEALTHCHECK --interval=30s \
            --timeout=10s \
            --start-period=40s \
            --retries=3 \
            CMD curl -f http://localhost:${PORT}/health || exit 1

# Definir ponto de entrada
ENTRYPOINT ["/app/server"]

# Comando padrão (pode ser sobrescrito)
CMD []

# =============================================================================
# Metadados adicionais
# =============================================================================

# Adicionar labels para melhor organização
LABEL org.opencontainers.image.title="SafeEdu API"
LABEL org.opencontainers.image.description="API para aplicativo SafeEdu - WorldSkills 2025"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.created="2025-06-07"
LABEL org.opencontainers.image.authors="WorldSkills Team"
LABEL org.opencontainers.image.url="https://safeedu-api.fly.dev"
LABEL org.opencontainers.image.documentation="https://github.com/safeedu/api/blob/main/README.md"
LABEL org.opencontainers.image.source="https://github.com/safeedu/api"
LABEL org.opencontainers.image.licenses="MIT"

# Informações sobre portas e volumes
LABEL ports.api="8080/tcp"
LABEL volumes.uploads="/app/uploads"
LABEL volumes.logs="/app/logs"

# Variáveis de ambiente documentadas
LABEL env.PORT="Porta do servidor (padrão: 8080)"
LABEL env.HOST="Host do servidor (padrão: 0.0.0.0)"
LABEL env.JWT_SECRET="Chave secreta para JWT"
LABEL env.ENVIRONMENT="Ambiente de execução (development/production)"
LABEL env.LOG_LEVEL="Nível de log (debug/info/warn/error)"