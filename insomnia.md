# 🧪 Teste Passo a Passo - SafeEdu API

## 📋 **Checklist de Testes**

### **✅ Rota 1: Health Check**
**Status:** ✅ **FUNCIONANDO**

---

## 🔍 **Rota 2: Debug Routes**

### **Configuração:**
- **Method:** GET
- **URL:** `http://localhost:8080/debug/routes`
- **Headers:** Nenhum necessário
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "available_routes": [
    "POST /jwt/generate_token - Autenticação",
    "POST /jwt/validate_token - Validar token",
    "GET  /A2/motd - Mensagem do dia",
    "GET  /A2/school_list - Lista de escolas",
    "GET  /A2/comments - Comentários",
    "POST /A2/comments - Adicionar comentário",
    "GET  /A2/prints - Lista de prints",
    "POST /A2/prints - Upload de print",
    "GET  /uploads/<fileName> - Arquivos estáticos",
    "GET  /health - Health check",
    "GET  /debug/routes - Esta rota"
  ],
  "note": "Todos os endpoints (exceto auth e motd) requerem Authorization: Bearer <token>"
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
- **URL:** `http://localhost:8080/jwt/generate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "email": "fred@fred.com",
    "password": "fred123"
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
  "expires_in": 86400,
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
- **URL:** `http://localhost:8080/jwt/generate_token`
- **Headers:** 
  ```
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "email": "julia@safeedu.com",
    "password": "123456"
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "2",
    "email": "julia@safeedu.com",
    "name": "Júlia"
  },
  "expires_in": 86400,
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
- **URL:** `http://localhost:8080/jwt/generate_token`
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
- **URL:** `http://localhost:8080/jwt/validate_token`
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
  "expires_at": "2025-06-08T20:10:00.000Z",
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
- **URL:** `http://localhost:8080/A2/motd`
- **Headers:** Nenhum necessário
- **Body:** Nenhum

### **Resultado Esperado:**
```json
{
  "message": "Bem-vindo ao SafeEdu! Sua segurança é nossa prioridade.",
  "timestamp": "2025-06-07T20:15:00.000Z",
  "version": "1.0.0"
}
```

### **✅ Status da Rota 7:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **MENSAGEM:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 🏫 **Rota 8: Lista de Escolas**

### **Configuração:**
- **Method:** GET
- **URL:** `http://localhost:8080/A2/school_list`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Nenhum

### **Resultado Esperado:**
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

### **✅ Status da Rota 8:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOTAL ESCOLAS:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 🚫 **Rota 9: Escolas Sem Token (Teste de Erro)**

### **Configuração:**
- **Method:** GET
- **URL:** `http://localhost:8080/A2/school_list`
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
- **URL:** `http://localhost:8080/A2/comments`
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
      "school_id": "1",
      "user_id": "1",
      "user_name": "Frederico",
      "comment": "Excelente escola! Meus filhos adoram estudar aqui.",
      "created_at": "2025-06-05T12:00:00.000Z",
      "parent_id": null
    }
  ],
  "total": 4,
  "school_id": null,
  "message": "Comentários obtidos com sucesso"
}
```

### **✅ Status da Rota 10:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **TOTAL COMENTÁRIOS:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 💬 **Rota 11: Comentários por Escola**

### **Configuração:**
- **Method:** GET
- **URL:** `http://localhost:8080/A2/comments?school_id=1`
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
      "school_id": "1",
      "user_id": "1",
      "user_name": "Frederico",
      "comment": "Excelente escola! Meus filhos adoram estudar aqui.",
      "created_at": "2025-06-05T12:00:00.000Z",
      "parent_id": null
    }
  ],
  "total": 2,
  "school_id": "1",
  "message": "Comentários obtidos com sucesso"
}
```

### **✅ Status da Rota 11:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **COMENTÁRIOS DA ESCOLA 1:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## ✍️ **Rota 12: Adicionar Comentário**

### **Configuração:**
- **Method:** POST
- **URL:** `http://localhost:8080/A2/comments`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "id_escola": "1",
    "comentario": "Comentário de teste via Insomnia! Escola muito boa."
  }
  ```

### **Resultado Esperado:**
```json
{
  "success": true,
  "message": "Comentário adicionado com sucesso",
  "comment": {
    "id": "5",
    "school_id": "1",
    "user_id": "1",
    "user_name": "Frederico",
    "comment": "Comentário de teste via Insomnia! Escola muito boa.",
    "created_at": "2025-06-07T20:20:00.000Z",
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
- **URL:** `http://localhost:8080/A2/comments`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  Content-Type: application/json
  ```
- **Body (JSON):**
  ```json
  {
    "id_escola": "999",
    "comentario": ""
  }
  ```

### **Resultado Esperado:**
```json
{
  "error": "Dados obrigatórios ausentes",
  "message": "id_escola e comentario são obrigatórios"
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
- **URL:** `http://localhost:8080/A2/prints`
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

## 📤 **Rota 15: Upload de Print**

### **Configuração:**
- **Method:** POST
- **URL:** `http://localhost:8080/A2/prints`
- **Headers:** 
  ```
  Authorization: Bearer SEU_TOKEN_AQUI
  ```
- **Body:** Multipart Form
  ```
  id_user: 1
  imagem: [Selecionar arquivo PNG/JPG]
  ```

### **Como configurar no Insomnia:**
1. Selecione **Body Type:** "Multipart Form"
2. Adicione campo **`id_user`** (Text): `1`
3. Adicione campo **`imagem`** (File): Clique em "Choose File"

### **Resultado Esperado:**
```json
{
  "success": true,
  "message": "Print enviado com sucesso",
  "print": {
    "id": "1",
    "user_id": "1",
    "file_name": "print_1686158400000.png",
    "created_at": "2025-06-07T20:25:00.000Z"
  },
  "file_url": "/uploads/print_1686158400000.png"
}
```

### **✅ Status da Rota 15:**
- [ ] **TESTE:** Executar no Insomnia
- [ ] **RESULTADO:** Status 200 ✅ / Erro ❌
- [ ] **ARQUIVO SALVO:** _______________
- [ ] **OBSERVAÇÕES:** _______________

---

## 📊 **Resumo Final**

### **Estatísticas:**
- **Total de rotas testadas:** ___/15
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

### **Ordem recomendada:**
1. Debug Routes (2)
2. Login Fred (3)
3. Validar Token (6)
4. MOTD (7)
5. Lista Escolas (8)
6. Listar Comentários (10)
7. Adicionar Comentário (12)
8. Listar Prints (14)
9. Upload Print (15)
10. Testes de erro (5, 9, 13)

**Vamos começar pela Rota 2 (Debug Routes)?** 🎯