# 🧪 Teste Passo a Passo - BiblioTech API

## 📋 **Checklist de Testes**

### **✅ Rota 1: Health Check**
**Status:** ✅ **FUNCIONANDO**

---

## 🔍 **Rota 2: Debug Routes**

### **Configuração:**
- **Method:*## 📚 **Rota 8: Lista de Bibliotecas**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/library_list`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```**URL:** `https://bibliotech-api.fly.dev/debug/routes`
- **Headers:** Nenhum necessário
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "available_routes": [
    "POST /worldskills/bibliotech/jwt/generate_token - Autenticação",
    "POST /worldskills/bibliotech/jwt/validate_token - Validar token",
    "GET  /worldskills/bibliotech/motd - Mensagem do dia",
    "GET  /worldskills/bibliotech/library_list - Lista de bibliotecas",
    "GET  /worldskills/bibliotech/comments - Comentários",
    "POST /worldskills/bibliotech/comments - Adicionar comentário",
    "GET  /worldskills/bibliotech/prints - Lista de prints",
    "POST /worldskills/bibliotech/prints - Upload de print",
    "GET  /uploads/<fileName> - Arquivos estáticos",
    "GET  /health - Health check",
    "GET  /debug/routes - Esta rota"
  ],
  "note": "Todos os endpoints (exceto auth, validate e motd) requerem Authorization: Bearer <token>",
  "api": "BiblioTech API v1.0",
  "company": "EduLib"
}
```

### **✅ Status da Rota 2:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## 🔐 **Rota 3: Login (Fred)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/jwt/generate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "email": "fred@fred.com",
    "password": "123abc@"
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "1",
    "email": "fred@fred.com",
    "name": "Frederico"
  },
  "expires_in": 300,
  "message": "Login realizado com sucesso"
}
```

### **✅ Status da Rota 3:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOKEN SALVO:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 🔐 **Rota 4: Login (Júlia)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/jwt/generate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "email": "julia@edulib.com",
    "password": "julia123!"
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "2",
    "email": "julia@edulib.com",
    "name": "Júlia Silva"
  },
  "expires_in": 300,
  "message": "Login realizado com sucesso"
}
```

### **✅ Status da Rota 4:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## ❌ **Rota 5: Login Inválido (Teste de Erro)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/jwt/generate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "email": "fred@fred.com",
    "password": "senha_errada"
  }
  ```

### **Resultado Esperado:**
```json
{
  "error": "Senha incorreta",
  "message": "A senha fornecida não confere"
}
```

### **✅ Status da Rota 5:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 401 ✅ / Outro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## 🔍 **Rota 6: Validar Token**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/jwt/validate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "token": "SEU_TOKEN_DO_LOGIN_AQUI"
  }
  ```

### **Resultado Esperado:**
```json
{
  "valid": true,
  "user": {
    "id": "1",
    "email": "fred@fred.com",
    "name": "Frederico"
  },
  "expires_at": "2025-07-07T20:10:00.000Z",
  "message": "Token válido"
}
```

### **✅ Status da Rota 6:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## 📄 **Rota 7: MOTD (Message of the Day)**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/motd`
- **Headers:** Nenhum necessário
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "message": "Bem-vindo ao BiblioTech! Conectando você às melhores bibliotecas.",
  "timestamp": "2025-07-07T20:15:00.000Z",
  "version": "1.0.0"
}
```

### **✅ Status da Rota 7:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **MENSAGEM:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## �️ **Rota 8: Lista de Bibliotecas**

### **Configuração:**
- **Method:** GET
- **URL:** `http://localhost:8080/worldskills/bibliotech/library_list`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "success": true,
  "libraries": [
    {
      "id": 1,
      "nome": "Biblioteca Central UFCE",
      "avaliacao": 5,
      "latitude": -3.7436,
      "longitude": -38.5267,
      "endereco": "Campus do Pici - Fortaleza",
      "foto": "https://picsum.photos/400/300?random=1",
      "data_cadastro": "2024-12-15T10:00:00.000Z"
    }
  ],
  "total": 5,
  "message": "Lista de bibliotecas obtida com sucesso"
}
```

### **✅ Status da Rota 8:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOTAL BIBLIOTECAS:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 🚫 **Rota 9: Bibliotecas Sem Token (Teste de Erro)**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/library_list`
- **Headers:** Nenhum (sem Authorization)
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "error": "Token de acesso requerido",
  "message": "Forneça um token válido no header Authorization: Bearer <token>"
}
```

### **✅ Status da Rota 9:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 401 ✅ / Outro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## 💬 **Rota 10: Listar Comentários**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/comments`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "success": true,
  "comments": [
    {
      "id": "1",
      "id_biblioteca": "1",
      "user_id": "1",
      "user_name": "Frederico",
      "comentario": "Excelente biblioteca! Acervo muito amplo e ambiente agradável.",
      "created_at": "2025-07-05T12:00:00.000Z",
      "parent_id": null
    }
  ],
  "total": 4,
  "id_biblioteca": null,
  "message": "Comentários obtidos com sucesso"
}
```

### **✅ Status da Rota 10:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOTAL COMENTÁRIOS:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 💬 **Rota 11: Comentários por Biblioteca**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/comments?id_biblioteca=1`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "success": true,
  "comments": [
    {
      "id": "1",
      "id_biblioteca": "1",
      "user_id": "1",
      "user_name": "Frederico",
      "comentario": "Excelente biblioteca! Acervo muito amplo e ambiente agradável.",
      "created_at": "2025-07-05T12:00:00.000Z",
      "parent_id": null
    }
  ],
  "total": 2,
  "id_biblioteca": "1",
  "message": "Comentários obtidos com sucesso"
}
```

### **✅ Status da Rota 11:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **COMENTÁRIOS DA BIBLIOTECA 1:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## ✍️ **Rota 12: Adicionar Comentário**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/comments`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "id_biblioteca": "1",
    "comentario": "Comentário de teste via Insomnia! Biblioteca muito boa."
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "message": "Comentário adicionado com sucesso",
  "comment": {
    "id": "5",
    "id_biblioteca": "1",
    "user_id": "1",
    "user_name": "Frederico",
    "comentario": "Comentário de teste via Insomnia! Biblioteca muito boa.",
    "created_at": "2025-07-07T20:20:00.000Z",
    "parent_id": null
  }
}
```

### **✅ Status da Rota 12:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **ID DO NOVO COMENTÁRIO:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## ❌ **Rota 13: Comentário Inválido (Teste de Erro)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/comments`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "id_biblioteca": "999",
    "comentario": ""
  }
  ```

### **Resultado Esperado:**
```json
{
  "error": "Dados obrigatórios ausentes",
  "message": "id_biblioteca e comentario são obrigatórios"
}
```

### **✅ Status da Rota 13:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 400 ✅ / Outro ❌
- [ ] **OBSERVAÇÕES:** _______________

---

## 🖼️ **Rota 14: Listar Prints**

### **Configuração:**
- **Method:** GET
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/prints`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "success": true,
  "prints": [],
  "total": 0,
  "message": "Lista de prints obtida com sucesso"
}
```

### **✅ Status da Rota 14:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOTAL PRINTS:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 📤 **Rota 15: Upload de Print (JSON)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/prints`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "id_user": "1"
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "message": "Print enviado com sucesso",
  "print": {
    "id": "1",
    "user_id": "1",
    "file_name": "print_bibliotech_1719999999999.png",
    "created_at": "2025-07-07T20:25:00.000Z"
  },
  "file_url": "/uploads/print_bibliotech_1719999999999.png",
  "mode": "JSON simulado"
}
```

### **✅ Status da Rota 15:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **ARQUIVO SALVO:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 📤 **Rota 16: Upload de Print (Multipart)**

### **Configuração:**
- **Method:** POST
- **URL:** `https://bibliotech-api.fly.dev/worldskills/bibliotech/prints`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Multipart Form
  ```
  Nenhum campo necessário para o teste
  ```

### **Como configurar no Insomnia:**
1. Selecione **Body Type:** "Multipart Form"
2. **Nota:** A API simula o upload mesmo sem arquivo

### **Resultado Esperado:**
```json
{
  "success": true,
  "message": "Print enviado com sucesso",
  "print": {
    "id": "2",
    "user_id": "1",
    "file_name": "print_bibliotech_multipart_1719999999999.png",
    "created_at": "2025-07-07T20:25:00.000Z"
  },
  "file_url": "/uploads/print_bibliotech_multipart_1719999999999.png",
  "mode": "Multipart"
}
```

### **✅ Status da Rota 16:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **ARQUIVO SALVO:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 📊 **Resumo Final**

### **Estatísticas:**
- **Total de rotas testadas:** ___/16
- **Sucessos:** ___
- **Falhas:** ___
- **Taxa de sucesso:** ___%

### **Rotas com problemas:**
- [ ] Rota ___: _______________
- [ ] Rota ___: _______________
- [ ] Rota ___: _______________

### **Próximos passos:**
- [ ] Corrigir erros encontrados
- [ ] Testar novamente rotas que falharam
- [ ] Documentar problemas específicos
- [ ] Deploy em produção

---

## 🚀 **Instruções de Teste**

### **Como usar este checklist:**
1. **Copie o token** do login (Rota 3) 
2. **Cole nas rotas** que precisam de autenticação
3. **Marque ✅** cada rota testada
4. **Anote observações** para cada teste
5. **Reporte problemas** encontrados

### **Credenciais de teste:**
- **fred@fred.com** / **123abc@**
- **julia@edulib.com** / **julia123!**
- **admin@edulib.com** / **admin2024#**

### **⚠️ IMPORTANTE:**
- **Tokens expiram em 5 minutos** (para avaliação)
- **Senhas devem ter símbolos obrigatórios**
- **Bibliotecas ordenadas por data de cadastro**

### **Ordem recomendada:**
1. Debug Routes (2)
2. Login Fred (3)
3. Validar Token (6)
4. MOTD (7)
5. Lista Bibliotecas (8)
6. Listar Comentários (10)
7. Adicionar Comentário (12)
8. Listar Prints (14)
9. Upload Print JSON (15)
10. Upload Print Multipart (16)
11. Testes de erro (5, 9, 13)

**Vamos começar pela Rota 2 (Debug Routes)?** 🎯