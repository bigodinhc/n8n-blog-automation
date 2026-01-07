# Guia de Configuracao de Credenciais - LinkedIn e Instagram

> Atualizado: 2026-01-06

Este documento detalha o processo completo para configurar credenciais das APIs do LinkedIn e Instagram para uso no n8n.

---

## 1. LinkedIn API

### Pre-requisitos

- Perfil pessoal no LinkedIn
- Acesso de admin a uma **Company Page** (ou criar uma)
- Logo da empresa (min 100x100px)
- URL de privacy policy

### Passo 1: Criar App no Developer Portal

1. Acesse: https://www.linkedin.com/developers/
2. Faca login com sua conta LinkedIn
3. Clique em **"Create app"**
4. Preencha:
   - **App name:** `MineralsTradingDaily`
   - **LinkedIn Page:** Selecione sua Company Page
   - **App logo:** Faca upload
   - **Legal agreement:** Aceite os termos

### Passo 2: Obter Credenciais

Apos criar o app:
1. Va para aba **"Auth"**
2. Anote:
   - **Client ID:** (publico, pode usar em config)
   - **Client Secret:** (SECRETO - guardar seguro!)

### Passo 3: Configurar Redirect URIs

Na aba **"Auth"** → **"OAuth 2.0 settings"**:
```
https://seu-dominio-n8n.com/rest/oauth2-credential/callback
```

Para desenvolvimento local:
```
http://localhost:5678/rest/oauth2-credential/callback
```

### Passo 4: Solicitar Produtos/Permissoes

Na aba **"Products"**, adicione os seguintes produtos:

#### Para postar como PESSOA (perfil pessoal):
- **Share on LinkedIn** - habilita `w_member_social`
- **Sign In with LinkedIn using OpenID Connect** - habilita `openid`, `profile`, `email`

#### Para postar como EMPRESA (Company Page):
- **Marketing API** - habilita `w_organization_social` (REQUER APROVACAO)

> **IMPORTANTE:** O scope `w_organization_social` requer que voce solicite acesso ao Marketing API e seja aprovado pelo LinkedIn. Isso pode levar dias/semanas.

### Passo 5: Verificar Company Page

1. Na aba **"Settings"** do app
2. Clique em **"Verify"** ao lado da Company Page
3. Siga as instrucoes para verificar que voce tem autoridade sobre a page

### Passo 6: Configurar no n8n

1. No n8n, va para **Credentials**
2. Crie nova credencial **"LinkedIn OAuth2 API"**
3. Preencha:
   - **Client ID:** (do passo 2)
   - **Client Secret:** (do passo 2)
4. Clique **"Connect my account"**
5. Autorize no popup do LinkedIn

### Scopes Disponiveis

| Scope | Produto Necessario | Funcao |
|-------|-------------------|--------|
| `openid` | Sign In with LinkedIn | Autenticacao OpenID |
| `profile` | Sign In with LinkedIn | Dados basicos do perfil |
| `email` | Sign In with LinkedIn | Email do usuario |
| `w_member_social` | Share on LinkedIn | Postar como pessoa |
| `w_organization_social` | Marketing API | Postar como empresa |
| `r_organization_social` | Marketing API | Ler posts da empresa |
| `rw_organization_admin` | Marketing API | Admin da org |

### Notas Importantes

- Token valido por **60 dias**
- Refresh token valido por **365 dias**
- Aguarde ~5 min apos criar o app antes de usar as credenciais
- Para postar como Company Page, e necessario aprovacao do Marketing API

### Troubleshooting LinkedIn

#### Erro: `unauthorized_scope_error` para `w_organization_social`

**Causa:** O app nao tem o produto Marketing API habilitado/aprovado.

**Solucoes:**

1. **Postar como pessoa (mais rapido):**
   - Use apenas o scope `w_member_social`
   - Nao requer aprovacao adicional
   - Posts aparecem no perfil pessoal, nao na Company Page

2. **Postar como empresa (requer aprovacao):**
   - Va para aba "Products" no Developer Portal
   - Solicite acesso ao "Marketing API"
   - Preencha o formulario de solicitacao
   - Aguarde aprovacao (pode levar dias)

3. **Configurar n8n para usar apenas scopes disponiveis:**
   - Na credential do n8n, verifique se ha opcao de customizar scopes
   - Remova `w_organization_social` se nao aprovado

---

## 2. Instagram Graph API

### Pre-requisitos

- Conta Instagram **Business** ou **Creator** (NAO pessoal!)
- **Facebook Page** vinculada a conta Instagram
- Conta no Meta for Developers

### Passo 1: Converter Instagram para Business

No app Instagram:
1. Va para **Configuracoes** → **Conta**
2. Toque em **"Mudar para conta profissional"**
3. Escolha **"Business"** (para empresa) ou **"Creator"**
4. Selecione categoria do negocio
5. Confirme

### Passo 2: Vincular Instagram ao Facebook Page

No app Instagram:
1. **Configuracoes** → **Conta** → **Compartilhamento em outros apps**
2. Selecione **Facebook**
3. Faca login no Facebook
4. Escolha a **Page** para vincular
5. Confirme a conexao

### Passo 3: Criar App no Meta Developers

1. Acesse: https://developers.facebook.com/
2. Clique em **"My Apps"** → **"Create App"**
3. Selecione **"Business"** como tipo
4. Preencha:
   - **App name:** `MineralsTradingDaily`
   - **Contact email:** seu email
5. Clique **"Create App"**

### Passo 4: Adicionar Instagram ao App

1. No dashboard do app, clique em **"Add Product"**
2. Encontre **"Instagram"** e clique **"Set Up"**
3. Selecione **"Instagram Graph API"**

### Passo 5: Configurar OAuth

1. Va para **App Settings** → **Basic**
2. Anote:
   - **App ID**
   - **App Secret** (clique em "Show")
3. Em **Instagram** → **Basic Display**:
   - Adicione **Valid OAuth Redirect URIs:**
   ```
   https://seu-dominio-n8n.com/rest/oauth2-credential/callback
   ```

### Passo 6: Obter Access Token

#### Opcao A - Via Graph API Explorer (teste):

1. Acesse: https://developers.facebook.com/tools/explorer/
2. Selecione seu app
3. Clique em **"Get User Access Token"**
4. Marque permissoes:
   - `instagram_basic`
   - `instagram_content_publish`
   - `pages_show_list`
   - `pages_read_engagement`
5. Clique **"Generate Access Token"**
6. Autorize

#### Opcao B - Via n8n (producao):

1. No n8n, crie credencial **"Instagram Graph API"**
2. Use App ID e App Secret
3. Conecte sua conta

### Passo 7: Obter Instagram Business Account ID

```bash
# Com seu access token, faca:
curl -X GET "https://graph.facebook.com/v18.0/me/accounts?access_token=SEU_TOKEN"
```

Isso retorna as Pages. Para cada Page, obtenha o Instagram ID:

```bash
curl -X GET "https://graph.facebook.com/v18.0/{page-id}?fields=instagram_business_account&access_token=SEU_TOKEN"
```

### Passo 8: Trocar por Long-Lived Token

Token curto (1h) → Token longo (60 dias):

```bash
curl -X GET "https://graph.facebook.com/v18.0/oauth/access_token?grant_type=fb_exchange_token&client_id={app-id}&client_secret={app-secret}&fb_exchange_token={short-lived-token}"
```

### Permissoes Instagram

| Permissao | Funcao | Access Level |
|-----------|--------|--------------|
| `instagram_basic` | Ler perfil basico | Standard |
| `instagram_content_publish` | Publicar conteudo | Advanced (App Review) |
| `instagram_manage_comments` | Gerenciar comentarios | Advanced |
| `instagram_manage_insights` | Acessar analytics | Advanced |
| `pages_show_list` | Listar Pages | Standard |
| `pages_read_engagement` | Ler engagement | Standard |

### Notas Importantes

- Token valido por **60 dias** (renovar antes!)
- Rate limit: **200 requests/hora** por conta
- Limite de publicacao: **100 posts/24h**
- Basic Display API foi **descontinuada em Dez/2024**
- `instagram_content_publish` requer **App Review** para Advanced Access

### Troubleshooting Instagram

#### Erro: Permissao negada para `instagram_content_publish`

**Causa:** Requer Advanced Access via App Review.

**Solucao:**
1. Va para **App Review** no Meta Developer Dashboard
2. Solicite Advanced Access para `instagram_content_publish`
3. Preencha o formulario explicando o uso
4. Aguarde aprovacao

#### Erro: Instagram account not found

**Causa:** Instagram nao esta vinculado a Facebook Page.

**Solucao:** Siga o Passo 2 para vincular as contas.

---

## Resumo de Credenciais

### LinkedIn

| Campo | Onde Encontrar |
|-------|----------------|
| Client ID | LinkedIn Developer Portal → Auth |
| Client Secret | LinkedIn Developer Portal → Auth |
| Redirect URI | Configurar no portal |

### Instagram

| Campo | Onde Encontrar |
|-------|----------------|
| App ID | Meta Developers → App Settings → Basic |
| App Secret | Meta Developers → App Settings → Basic |
| Instagram Business Account ID | Via API (passo 7) |
| Access Token | Graph API Explorer ou OAuth flow |

---

## Checklist de Configuracao

### LinkedIn
- [ ] App criado no Developer Portal
- [ ] Company Page verificada
- [ ] Redirect URI configurada
- [ ] Produto "Share on LinkedIn" habilitado
- [ ] (Opcional) Marketing API aprovado para posts como empresa
- [ ] Credential criada no n8n
- [ ] Teste de conexao OK

### Instagram
- [ ] Conta convertida para Business/Creator
- [ ] Facebook Page criada e vinculada
- [ ] App criado no Meta Developers
- [ ] Instagram Graph API adicionado ao app
- [ ] Redirect URI configurada
- [ ] Access Token obtido
- [ ] Token trocado por Long-Lived
- [ ] (Opcional) App Review para `instagram_content_publish`
- [ ] Credential criada no n8n
- [ ] Teste de conexao OK

---

## Referencias

- LinkedIn Developer Portal: https://www.linkedin.com/developers/
- LinkedIn API Docs: https://learn.microsoft.com/en-us/linkedin/
- Meta Developers: https://developers.facebook.com/
- Instagram Graph API: https://developers.facebook.com/docs/instagram-platform/
- Graph API Explorer: https://developers.facebook.com/tools/explorer/
