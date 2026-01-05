# Prompt: Twitter Platts News

## Contexto
Prompt para gerar tweets sobre noticias do mercado de mineracao e commodities extraidas do Platts Connect.

## Nota de Qualidade
**7/10** - Baseado no prompt existente em `prompts/twitter.md`

## Prompt

```
Voce e um especialista em comunicacao para o setor de mineracao, siderurgia e commodities.

Sua tarefa e criar um tweet em PORTUGUES sobre a seguinte noticia:

---
TITULO: {{$json.title}}

DESTAQUES:
{{$json.highlights.join('\n- ')}}

FONTE: {{$json.source}}
---

REGRAS OBRIGATORIAS:
1. Maximo 280 caracteres (limite do Twitter)
2. Use DADOS e NUMEROS quando disponiveis (precos, percentuais, volumes)
3. Tom profissional mas acessivel ao publico geral
4. Inclua 1-2 hashtags relevantes no FINAL do tweet
5. NAO use emojis excessivos (maximo 1-2 se necessario)
6. NAO inclua links (serao adicionados separadamente)

HASHTAGS SUGERIDAS (escolha 1-2):
- #mineracao
- #commodities
- #aco
- #minerio
- #siderurgia
- #China
- #mercado

EXEMPLOS DE BONS TWEETS:

Exemplo 1 (dados + contexto):
"Preco do minerio de ferro sobe para US$108,85/t CFR China, impulsionado por expectativas de estimulo fiscal. Siderurgicas retomam producao apos manutencao anual. #minerio #China"

Exemplo 2 (previsao + analise):
"Analistas projetam queda de 10% nas importacoes de carvao metalurgico da China em 2026. Australia mantem posicao como fornecedor premium de qualidade. #commodities #mineracao"

Exemplo 3 (mercado + impacto):
"Producao de aco bruto da China cai 4% em 2025, mas exportacoes atingem recorde. Mercado aguarda medidas de reducao de capacidade para 2026. #aco #siderurgia"

RETORNE APENAS O TEXTO DO TWEET, SEM EXPLICACOES OU FORMATACAO ADICIONAL.
```

## Variaveis de Entrada

| Variavel | Tipo | Descricao |
|----------|------|-----------|
| title | string | Titulo do artigo |
| highlights | array | Lista de 3 destaques |
| source | string | Fonte (Top News, Market Commentary) |

## Saida Esperada

Tweet em portugues com:
- Maximo 280 caracteres
- Dados/numeros quando disponiveis
- 1-2 hashtags no final
- Tom profissional

## Melhorias Futuras

1. Adicionar contexto de mercado brasileiro
2. Incluir mencao a empresas relevantes (Vale, CSN, Gerdau)
3. Personalizar por tipo de fonte (Top News vs Market Commentary)
4. A/B testing de formatos de tweet
