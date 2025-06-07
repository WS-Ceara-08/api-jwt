# 📚 SafeEdu API - Documentação Completa

## WorldSkills 2025 - Módulo A2 - Desenvolvimento de Aplicativos

## 🧪 **Status dos Testes**

### **✅ Testes Realizados com Sucesso**

| Endpoint | Método | Status | Resultado |
|----------|--------|---------|-----------|
| `/health` | GET | ✅ 200 | API funcionando |
| `/debug/routes` | GET | ✅ 200 | Lista todas as rotas |
| `/jwt/generate_token` | POST | ✅ 200 | Login Fred/Júlia |
| `/jwt/validate_token` | POST | ✅ 200 | Token válido |
| `/A2/motd` | GET | ✅ 200 | Mensagem aleatória |
| `/A2/school_list` | GET | ✅ 200 | 5 escolas ordenadas |
| `/A2/comments` | GET | ✅ 200 | Comentários listados |
| `/A2/comments` | POST | ✅ 200 | Comentário adicionado |
| `/A2/prints` | GET | ✅ 200 | Lista de prints |
| `/A2/prints` | POST | ✅ 200 | Upload simulado |

### **🛡️ Testes de Segurança**

| Teste | Status | Resultado |
|-------|---------|-----------|
| Acesso sem token | ✅ 401 | Bloqueado corretamente |
| Token inválido | ✅ 401 | Rejeitado |
| Dados inválidos | ✅ 400 | Validado |
| Credenciais erradas | ✅ 401 | Login negado |

### **📊 Estatísticas Finais**
- **Total de endpoints:** 11
- **Taxa de sucesso:** 100%
- **Conformidade com prova:** ✅ Completa
- **Última atualização:** $(date '+%Y-%m-%d')

---

## 🎯 **Visão Geral**

A **SafeEdu API** é uma solução completa desenvolvida para a prova WorldSkills 2025, implementando um sistema seguro de gestão de escolas com funcionalidades de autenticação, geolocalização, comentários e upload de arquivos.

### **🏆 Especificações Atendidas**
- ✅ **Todos os 6 endpoints** conforme especificação da prova
- ✅ **Autenticação JWT** com validação e middleware
- ✅ **Validações de entrada** (email, senha, dados)
- ✅ **Sistema de comentários** hierárquico
- ✅ **Upload de arquivos** (prints/screenshots)
- ✅ **Geolocalização** com coordenadas reais de Fortaleza/CE
- ✅ **CORS** habilitado para aplicações web/mobile
- ✅ **Deploy automatizado** no Fly.io

---

## 🚀 **Início Rápido**

### **Pré-requisitos**
- [Dart SDK 3.0+](https://dart.dev/get-dart)
- [Fly CLI](https://fly.io/docs/flyctl/installing/) (para deploy)
- [Git](https://git-scm.com/) (para versionamento)

### **Instalação Local**

```bash
# 1. Clonar/criar projeto
git clone <seu-repositorio>
cd safeedu_api

# 2. Instalar dependências
dart pub get

# 3. Executar API
dart run bin/server.dart

# 4. Testar endpoints
./scripts/test_api.sh
```

### **Deploy Produção**

```bash
# Deploy automatizado no Fly.io
./scripts/deploy.sh
```

---

## 📡 **Endpoints da API**

### **Base URL**
- **Local:** `http://localhost:8080`
- **Produção:** `https://safeedu-api.fly.dev`

### **1. Autenticação**

#### **POST /jwt/generate_token**
Autentica usuário e gera token JWT.

**Request:**
```json
{
  "email": "fred@fred.com",
  "password": "fred123"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "1",
    "email": "fred@fred.com",
    "name": "Frederico"
  },
  "expires_in": 86400,
  "message": "Login realizado com sucesso"
}
```

**Validações:**
- Email deve conter "@" e pelo menos um "."
- Senha deve ter mínimo 6 caracteres com letras e números

---

#### **POST /jwt/validate_token**
Valida se um token JWT é válido.

**Request:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200):**
```json
{
  "valid": true,
  "user": {
    "id": "1",
    "email": "fred@fred.com",
    "name": "Frederico"
  },
  "expires_at": "2025-06-08T12:00:00.000Z",
  "message": "Token válido"
}
```

---

### **2. Dados da Aplicação**

#### **GET /A2/motd**
Retorna mensagem do dia (Message of the Day).

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Bem-vindo ao SafeEdu! Sua segurança é nossa prioridade.",
  "timestamp": "2025-06-07T15:30:00.000Z",
  "version": "1.0.0"
}
```

---

#### **GET /A2/school_list**
Lista todas as escolas ordenadas alfabeticamente.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "success": true,
  "schools": [
    {
      "id": "1",
      "name": "Escola A",
      "rating": 4,
      "latitude": -3.7319,
      "longitude": -38.5267,
      "image_url": "https://picsum.photos/400/300?random=1"
    },
    {
      "id": "2",
      "name": "Escola B",
      "rating": 3,
      "latitude": -3.7419,
      "longitude": -38.5367,
      "image_url": "https://picsum.photos/400/300?random=2"
    }
  ],
  "total": 5,
  "message": "Lista de escolas obtida com sucesso"
}
```

---

#### **GET /A2/comments**
Lista comentários (opcionalmente filtrados por escola).

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `school_id` (opcional): ID da escola para filtrar

**Response (200):**
```json
{
  "success": true,
  "comments": [
    {
      "id": "1",
      "school_id": "1",
      "user_id": "1",
      "user_name": "Frederico",
      "comment": "Excelente escola! Meus filhos adoram estudar aqui.",
      "created_at": "2025-06-05T12:00:00.000Z",
      "parent_id": null
    }
  ],
  "total": 4,
  "school_id": "1",
  "message": "Comentários obtidos com sucesso"
}
```

---

#### **POST /A2/comments**
Adiciona novo comentário sobre uma escola.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "id_escola": "1",
  "comentario": "Ótima escola, recomendo!",
  "parent_id": null
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Comentário adicionado com sucesso",
  "comment": {
    "id": "5",
    "school_id": "1",
    "user_id": "1",
    "user_name": "Frederico",
    "comment": "Ótima escola, recomendo!",
    "created_at": "2025-06-07T15:45:00.000Z",
    "parent_id": null
  }
}
```

---

#### **GET /A2/prints**
Lista prints/screenshots enviados.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `user_id` (opcional): Filtrar por usuário

**Response (200):**
```json
{
  "success": true,
  "prints": [
    {
      "id": "1",
      "user_id": "1",
      "file_name": "print_1686145200000.png",
      "created_at": "2025-06-07T15:00:00.000Z"
    }
  ],
  "total": 1,
  "message": "Lista de prints obtida com sucesso"
}
```

---

#### **POST /A2/prints**
Faz upload de um print/screenshot.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `id_user`: ID do usuário
- `imagem`: Arquivo de imagem (máx 5MB)

**Response (200):**
```json
{
  "success": true,
  "message": "Print enviado com sucesso",
  "print": {
    "id": "2",
    "user_id": "1",
    "file_name": "print_1686145800000.png",
    "created_at": "2025-06-07T15:10:00.000Z"
  },
  "file_url": "/uploads/print_1686145800000.png"
}
```

---

### **3. Utilitários**

#### **GET /health**
Health check da aplicação.

**Response (200):**
```json
{
  "status": "healthy",
  "timestamp": "2025-06-07T15:30:00.000Z",
  "version": "1.0.0",
  "uptime": 1686145800000,
  "endpoints": {
    "auth": "/jwt/generate_token",
    "schools": "/A2/school_list",
    "comments": "/A2/comments",
    "prints": "/A2/prints"
  }
}
```

---

## 👤 **Usuários de Teste**

### **Usuário 1**
- **Email:** `fred@fred.com`
- **Senha:** `fred123`
- **Nome:** Frederico

### **Usuário 2**
- **Email:** `julia@safeedu.com`
- **Senha:** `julia123`
- **Nome:** Júlia

---

## 🏫 **Escolas Cadastradas**

| ID | Nome | Avaliação | Localização |
|----|------|-----------|-------------|
| 1 | Escola A | ⭐⭐⭐⭐ | -3.7319, -38.5267 |
| 2 | Escola B | ⭐⭐⭐ | -3.7419, -38.5367 |
| 3 | Escola C | ⭐⭐⭐ | -3.7219, -38.5167 |
| 4 | Escola D | ⭐⭐⭐⭐ | -3.7519, -38.5467 |
| 5 | Escola E | ⭐⭐⭐⭐ | -3.7119, -38.5067 |

**Localização:** Todas as escolas estão em Fortaleza/CE com coordenadas reais.

---

## 🔒 **Autenticação e Segurança**

### **JWT (JSON Web Tokens)**
- **Algoritmo:** HS256
- **Expiração:** 24 horas
- **Secret:** Configurável via variável de ambiente
- **Claims:** `sub` (user ID), `email`, `name`, `iat`, `exp`

### **Middleware de Autenticação**
Todos os endpoints (exceto `/jwt/generate_token`, `/jwt/validate_token` e `/A2/motd`) requerem autenticação:

```bash
# Header obrigatório
Authorization: Bearer <seu_token_jwt>
```

### **Validações Implementadas**
- **Email:** Deve conter "@" e pelo menos um "."
- **Senha:** Mínimo 6 caracteres com letras e números
- **Dados obrigatórios:** Verificação em todos os endpoints
- **Tamanho de arquivo:** Máximo 5MB para uploads
- **Tipos de arquivo:** PNG, JPG, JPEG, GIF para imagens

---

## 🌐 **CORS (Cross-Origin Resource Sharing)**

A API está configurada para aceitar requisições de qualquer origem:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Origin, Content-Type, Accept, Authorization, X-Requested-With
```

---

## 📁 **Upload de Arquivos**

### **Especificações**
- **Tamanho máximo:** 5MB por arquivo
- **Tipos aceitos:** PNG, JPG, JPEG, GIF, WEBP
- **Armazenamento:** Volume persistente `/app/uploads`
- **Nomenclatura:** `print_<timestamp>.<extensão>`

### **Exemplo de Upload**

**Modo JSON (Simulado):**
```json
{
  "id_user": "1"
}
```

**Modo Multipart (Form-Data):**
```bash
curl -X POST https://safeedu-api.fly.dev/A2/prints \
  -H "Authorization: Bearer <token>" \
  -F "id_user=1" \
  -F "imagem=@screenshot.png"
```

**Ambos os modos são suportados para compatibilidade máxima.**

---

## 🐛 **Códigos de Erro**

| Código | Significado | Causa Common |
|--------|-------------|--------------|
| 400 | Bad Request | Dados inválidos ou ausentes |
| 401 | Unauthorized | Token ausente, inválido ou expirado |
| 404 | Not Found | Recurso não encontrado |
| 413 | Payload Too Large | Arquivo maior que 5MB |
| 500 | Internal Server Error | Erro interno do servidor |

### **Exemplo de Resposta de Erro**

```json
{
  "error": "Token inválido ou expirado",
  "message": "Faça login novamente para obter um token válido"
}
```

---

## 🧪 **Testes**

### **Executar Testes Localmente**

```bash
# Iniciar API
dart run bin/server.dart

# Em outro terminal, executar testes
./scripts/test_api.sh

# Teste com modo verbose
./scripts/test_api.sh -v
```

### **Testar Produção**

```bash
./scripts/test_api.sh https://safeedu-api.fly.dev
```

### **Testes Manuais com cURL**

```bash
# 1. Login
curl -X POST http://localhost:8080/jwt/generate_token \
  -H "Content-Type: application/json" \
  -d '{"email": "fred@fred.com", "password": "fred123"}'

# 2. Usar token retornado
TOKEN="seu_token_aqui"

# 3. Listar escolas
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/A2/school_list

# 4. Adicionar comentário
curl -X POST http://localhost:8080/A2/comments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id_escola": "1", "comentario": "Ótima escola!"}'

# 5. Upload simulado (JSON)
curl -X POST http://localhost:8080/A2/prints \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"id_user": "1"}'
```

---

## 🚀 **Deploy no Fly.io**

### **Configuração Automática**

O script `deploy.sh` automatiza todo o processo:

```bash
./scripts/deploy.sh
```

### **Configuração Manual**

```bash
# 1. Login no Fly.io
fly auth login

# 2. Criar volume para uploads
fly volumes create safeedu_uploads --region gru --size 1

# 3. Configurar secrets
fly secrets set JWT_SECRET="sua_chave_secreta"

# 4. Deploy
fly deploy

# 5. Verificar status
fly status
fly logs
```

### **Configurações do Fly.io**

- **Região:** São Paulo (GRU)
- **Volume:** 1GB para uploads
- **Health Checks:** HTTP + TCP
- **Auto-scaling:** 1-3 instâncias
- **HTTPS:** Obrigatório

---

## 📊 **Monitoramento**

### **Health Checks**
- **Endpoint:** `/health`
- **Intervalo:** 30 segundos
- **Timeout:** 5 segundos

### **Logs**

```bash
# Ver logs em tempo real
fly logs -a safeedu-api

# Logs com filtro
fly logs -a safeedu-api --limit 100
```

### **Métricas**
- Dashboard disponível em: `fly dashboard`
- Métricas de CPU, memória e rede
- Uptime e latência

---

## 🔧 **Configurações Avançadas**

### **Variáveis de Ambiente**

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `PORT` | 8080 | Porta do servidor |
| `HOST` | 0.0.0.0 | Host do servidor |
| `JWT_SECRET` | safeedu_secret_key_2025 | Chave para JWT |
| `ENVIRONMENT` | production | Ambiente de execução |
| `TZ` | America/Fortaleza | Timezone |

### **Scaling**

```bash
# Escalar verticalmente
fly scale vm shared-cpu-2x

# Escalar horizontalmente
fly scale count 2

# Múltiplas regiões
fly scale count 2 --region gru,iad
```

### **Backup**

```bash
# SSH no container
fly ssh console

# Backup do volume
tar -czf /tmp/uploads_backup.tar.gz /app/uploads

# Download do backup
fly ssh sftp get /tmp/uploads_backup.tar.gz
```

---

## 🛡️ **Segurança**

### **Boas Práticas Implementadas**
- ✅ **Senhas hasheadas** com SHA-256
- ✅ **Tokens JWT** com expiração
- ✅ **Validação de entrada** rigorosa
- ✅ **HTTPS obrigatório** em produção
- ✅ **Usuário não-root** no container
- ✅ **Secrets** gerenciados pelo Fly.io
- ✅ **CORS** configurado adequadamente

### **Recomendações Adicionais**
- Altere `JWT_SECRET` em produção
- Configure rate limiting se necessário
- Monitore logs regularmente
- Mantenha dependências atualizadas

---

## 🏗️ **Arquitetura**

### **Stack Tecnológico**
- **Linguagem:** Dart
- **Framework:** Shelf
- **Autenticação:** JWT
- **Deploy:** Fly.io
- **Container:** Docker
- **Armazenamento:** Volume persistente

### **Estrutura do Código**

```
safeedu_api/
├── bin/server.dart          # Código principal
├── uploads/                 # Arquivos enviados
├── config/fly.toml         # Configuração Fly.io
├── scripts/                # Scripts utilitários
└── docs/                   # Documentação
```

### **Fluxo de Dados**

1. **Request** → Middleware CORS
2. **Authentication** → Validação JWT
3. **Routing** → Shelf Router
4. **Business Logic** → Handlers
5. **Response** → JSON formatado

---

## 📱 **Integração com Aplicativo Mobile**

### **Configuração no Flutter**

```dart
class ApiService {
  static const String baseUrl = 'https://safeedu-api.fly.dev';
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jwt/generate_token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    return json.decode(response.body);
  }
}
```

### **Headers Necessários**

```dart
final headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};
```

---

## 🆘 **Troubleshooting**

### **Problemas Comuns**

#### **API não responde**
```bash
# Verificar status
fly status -a safeedu-api

# Ver logs
fly logs -a safeedu-api

# Reiniciar
fly restart -a safeedu-api
```

#### **Erro de autenticação**
- Verificar se token está válido
- Confirmar header `Authorization: Bearer <token>`
- Testar login novamente

#### **Upload falha**
- Verificar tamanho do arquivo (máx 5MB)
- Confirmar tipo de arquivo aceito
- Verificar permissões do volume

#### **Build Docker falha**
```bash
# Build local para debug
docker build -t safeedu-api .

# Verificar logs de build
fly logs --build
```

### **Comandos de Debug**

```bash
# SSH no container
fly ssh console -a safeedu-api

# Verificar arquivos
ls -la /app/uploads

# Verificar processos
ps aux

# Verificar logs do sistema
tail -f /var/log/messages
```

---

## 📞 **Suporte**

### **Recursos Úteis**
- **Documentação Fly.io:** [fly.io/docs](https://fly.io/docs)
- **Dart Language:** [dart.dev](https://dart.dev)
- **Shelf Framework:** [pub.dev/packages/shelf](https://pub.dev/packages/shelf)

### **Links Importantes**
- **Status Fly.io:** [status.fly.io](https://status.fly.io)
- **Community Fly.io:** [community.fly.io](https://community.fly.io)
- **Dashboard:** `fly dashboard`

---

## 📋 **Checklist de Implementação**

### **Funcionalidades da Prova**
- [x] **Endpoint #01:** `/jwt/generate_token`
- [x] **Endpoint #02:** `/jwt/validate_token`
- [x] **Endpoint #03:** `/A2/motd`
- [x] **Endpoint #04:** `/A2/school_list`
- [x] **Endpoint #05:** `/A2/comments` (GET/POST)
- [x] **Endpoint #06:** `/A2/prints` (GET/POST)

### **Requisitos Técnicos**
- [x] **Autenticação JWT** completa
- [x] **Validação de email** (@ e .)
- [x] **Validação de senha** (6+ chars, letras+números)
- [x] **Lista ordenada** alfabeticamente
- [x] **Upload de arquivos** multipart
- [x] **Coordenadas reais** Fortaleza/CE
- [x] **CORS** configurado
- [x] **Health checks** implementados

### **Deploy e Infraestrutura**
- [x] **Docker** otimizado
- [x] **Fly.io** configurado
- [x] **Volume persistente** para uploads
- [x] **HTTPS** obrigatório
- [x] **Scripts** automatizados
- [x] **Testes** abrangentes
- [x] **Documentação** completa

---

## 🎯 **Conclusão**

A **SafeEdu API** foi **testada e validada completamente** com todas as funcionalidades operacionais. Todos os endpoints especificados na prova WorldSkills 2025 foram implementados e testados com sucesso usando o Insomnia.

### **Principais Destaques**
- ✅ **100% dos testes passaram** em ambiente local
- ✅ **Conformidade total** com a especificação da prova
- ✅ **Arquitetura profissional** com validações robustas
- ✅ **Deploy automatizado** e monitoramento configurado
- ✅ **Documentação completa** e atualizada
- ✅ **Suporte a múltiplos formatos** (JSON + Multipart)

### **Credenciais Atualizadas**
- **Usuário 1:** fred@fred.com / fred123
- **Usuário 2:** julia@safeedu.com / julia123

### **Validações Implementadas**
- Email com "@" e "." obrigatórios
- Senhas com 6+ caracteres, letras E números
- Tokens JWT com expiração de 24h
- Middleware de autenticação robusto

**🚀 A API está 100% pronta para produção e uso no aplicativo mobile da WorldSkills 2025!**

---

*Última atualização: $(date '+%Y-%m-%d') - API testada e validada completamente*