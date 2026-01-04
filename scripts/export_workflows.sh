#!/bin/bash
# ============================================
# BLOG SYSTEM - Export Workflows from n8n
# ============================================

# Configuracao
N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_API_KEY="${N8N_API_KEY:-your-api-key}"
OUTPUT_DIR="$(dirname "$0")/../workflows"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "Exportando workflows do n8n..."
echo "URL: $N8N_URL"
echo "============================================"

# Mapeamento de workflows para pastas
declare -A WORKFLOW_MAP=(
  # 00-utils
  ["dxVlQYOyMQ4xxaHt"]="00-utils/WF0_error_handler.json"
  ["OLgG9Y2iHQVujYXB"]="00-utils/ALERTS_proactive.json"
  ["qOtYC2eCKW7VHK9M"]="00-utils/CMD_telegram_commands.json"

  # 01-content-pipeline
  ["TgZ3HSnbbSVHsIzD"]="01-content-pipeline/WF1_feed_supabase.json"
  ["LfU5ddiFTiDSrUSp"]="01-content-pipeline/WF2_content_archiver.json"
  ["J7G0HJYT2yqL3WQq"]="01-content-pipeline/WF3_draft_review.json"
  ["Eqj6uTE4pFizUsKH"]="01-content-pipeline/WF4_callback_drafts.json"
  ["QElqWkwrvoxGKDN4"]="01-content-pipeline/WF4.5_feedback_capture.json"
  ["UoQK3JSa2tzPHpxW"]="01-content-pipeline/WF4.6_quick_edit_capture.json"
  ["bKvqmScFWW9KK8ur"]="01-content-pipeline/WF4.7_quick_edit_callbacks.json"
  ["5TuCwLZLlGdczwhU"]="01-content-pipeline/WF5_revision_processor.json"

  # 02-image-pipeline
  ["yr7VUG1VMi8o8fi9"]="02-image-pipeline/WF6_image_generator.json"
  ["vqW2Dt3FkbkQPHws"]="02-image-pipeline/WF6.5_image_approval.json"

  # 03-social-pipeline
  ["KkCUTo9KVfZkfZrE"]="03-social-pipeline/WF7_social_media_factory.json"
  ["ZvWogMCqmetav8Fa"]="03-social-pipeline/WF7.1_social_callback.json"
  ["t4M4Qav7y3860Bje"]="03-social-pipeline/WF7.2_image_callback.json"

  # 04-newsletter-pipeline
  ["gMknz5KYcdJuu1Eg"]="04-newsletter-pipeline/WF8_newsletter_generator.json"
  ["e88ZJNv0ffG8nILx"]="04-newsletter-pipeline/WF8.1_newsletter_callback.json"
)

# Contador
SUCCESS=0
FAILED=0

# Exportar cada workflow
for WF_ID in "${!WORKFLOW_MAP[@]}"; do
  OUTPUT_FILE="${OUTPUT_DIR}/${WORKFLOW_MAP[$WF_ID]}"

  echo -n "Exportando $WF_ID -> ${WORKFLOW_MAP[$WF_ID]}... "

  # Fazer request para API do n8n
  HTTP_CODE=$(curl -s -o "$OUTPUT_FILE" -w "%{http_code}" \
    -H "X-N8N-API-KEY: $N8N_API_KEY" \
    "$N8N_URL/api/v1/workflows/$WF_ID")

  if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}OK${NC}"
    ((SUCCESS++))
  else
    echo -e "${RED}FALHOU (HTTP $HTTP_CODE)${NC}"
    rm -f "$OUTPUT_FILE" 2>/dev/null
    ((FAILED++))
  fi
done

echo ""
echo "============================================"
echo -e "Exportados: ${GREEN}$SUCCESS${NC}"
echo -e "Falharam:   ${RED}$FAILED${NC}"
echo "============================================"

# Verificar se precisa de API key
if [ $FAILED -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}DICA: Configure as variaveis de ambiente:${NC}"
  echo "  export N8N_URL=https://seu-n8n.com"
  echo "  export N8N_API_KEY=sua-api-key"
fi
