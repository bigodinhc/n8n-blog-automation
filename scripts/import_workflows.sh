#!/bin/bash
# ============================================
# BLOG SYSTEM - Import Workflows to n8n
# ============================================

# Configuracao
N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-your-api-key}"
INPUT_DIR="$(dirname "$0")/../workflows"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "Importando workflows para n8n..."
echo "URL: $N8N_URL"
echo "============================================"

# Contador
SUCCESS=0
FAILED=0

# Encontrar todos os arquivos JSON
for JSON_FILE in $(find "$INPUT_DIR" -name "*.json" -type f); do
  FILENAME=$(basename "$JSON_FILE")

  echo -n "Importando $FILENAME... "

  # Fazer request para API do n8n
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    -H "Content-Type: application/json" \
    -d @"$JSON_FILE" \
    "$N8N_URL/api/v1/workflows")

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo -e "${GREEN}OK${NC}"
    ((SUCCESS++))
  else
    echo -e "${RED}FALHOU (HTTP $HTTP_CODE)${NC}"
    ((FAILED++))
  fi
done

echo ""
echo "============================================"
echo -e "Importados: ${GREEN}$SUCCESS${NC}"
echo -e "Falharam:   ${RED}$FAILED${NC}"
echo "============================================"

if [ $SUCCESS -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}IMPORTANTE:${NC}"
  echo "1. Verifique as credenciais em cada workflow"
  echo "2. Ative os workflows necessarios"
  echo "3. Configure os webhooks do Telegram"
fi
