// Gerar HTML da Newsletter com design Neo Brutalista
const data = $('PARSE AI RESPONSE').first().json;
const initData = $('INIT DATA').first().json;

// Dados Baltic do CONSOLIDAR DADOS
const baltic = data.baltic || null;

// Configuracoes de Estilo Brutalista
const STYLES = {
  bgPage: '#f0f0f0',
  bgContainer: '#ffffff',
  primary: '#000000',     // Preto puro
  accent: '#F7931E',      // Laranja da marca
  success: '#22c55e',     // Verde para altas
  danger: '#ef4444',      // Vermelho para baixas
  border: '3px solid #000000',
  shadow: '6px 6px 0px #000000',
  shadowSmall: '3px 3px 0px #000000',
  font: "Consolas, 'Courier New', monospace"
};

const LOGO_URL = 'https://mineralstradingdaily.com.br/wp-content/uploads/2025/12/Logo-cor.png';

const subject = data.subject || data.newsletter_content?.subject_line || `Minerals Trading Daily - ${initData.date_display}`;
const content = data.newsletter_content || {};
const resumo = content.resumo_executivo || '';
const destaques = content.destaques || [];
const perspectivas = content.perspectivas || '';

// Buscar precos ja formatados
const benchmarks = data.benchmarks || [];
const differentials = data.differentials || [];
const priceData = data.price_data || {};
const iodexPrice = priceData.iodex_62 || '---';

// --- HELPERS DE FORMATACAO BRUTALISTA ---

// Formatar linha de preco (Benchmarks)
const formatPriceRow = (item) => {
  const change = parseFloat(item.change) || 0;
  const changeColor = change > 0 ? STYLES.success : (change < 0 ? STYLES.danger : '#888');
  const changeSymbol = change > 0 ? '▲' : (change < 0 ? '▼' : '●');
  
  // Design: Linhas com bordas pretas definidas
  return `<tr>
    <td style="padding: 10px; border: 2px solid #000; font-family: ${STYLES.font}; font-size: 13px; color: #000;">
        <strong>${item.name}</strong>
    </td>
    <td style="padding: 10px; border: 2px solid #000; font-family: ${STYLES.font}; text-align: right; font-weight: 900; color: #000;">
        US$ ${item.price}
    </td>
    <td style="padding: 10px; border: 2px solid #000; font-family: ${STYLES.font}; text-align: right;">
        <span style="color: ${changeColor}; font-weight: bold; font-size: 13px;">${changeSymbol} ${Math.abs(change).toFixed(2)}</span>
    </td>
  </tr>`;
};

// Formatar linha de diferencial (simples)
const formatDiffRow = (item) => {
  return `<tr>
    <td style="padding: 8px 10px; border: 2px solid #000; font-family: ${STYLES.font}; font-size: 12px; color: #000; background-color: #f9f9f9;">
        ${item.name}
    </td>
    <td style="padding: 8px 10px; border: 2px solid #000; font-family: ${STYLES.font}; text-align: right; font-weight: bold; color: #000;">
        US$ ${item.price}
    </td>
  </tr>`;
};

// Formatar linha Baltic
const formatBalticRow = (name, dataVal, showChange = true) => {
  if (!dataVal || dataVal.value === undefined) return '';
  const change = parseFloat(dataVal.change) || 0;
  const direction = dataVal.direction || (change > 0 ? 'UP' : change < 0 ? 'DOWN' : 'FLAT');
  const changeColor = direction === 'UP' ? STYLES.success : (direction === 'DOWN' ? STYLES.danger : '#888');
  const changeSymbol = direction === 'UP' ? '▲' : (direction === 'DOWN' ? '▼' : '●');
  
  const changeCell = showChange 
    ? `<td style="padding: 8px 10px; border-bottom: 1px dashed #000; text-align: right; font-family: ${STYLES.font}; font-size: 12px; color: ${changeColor}; font-weight: bold;">
         ${changeSymbol} ${Math.abs(change)}
       </td>` 
    : '';

  return `<tr>
    <td style="padding: 8px 10px; border-bottom: 1px dashed #000; font-family: ${STYLES.font}; font-size: 13px; color: #000;">
        ${name}
    </td>
    <td style="padding: 8px 10px; border-bottom: 1px dashed #000; text-align: right; font-family: ${STYLES.font}; font-weight: 900; color: #000;">
        ${typeof dataVal.value === 'number' ? dataVal.value.toLocaleString() : dataVal.value}
    </td>
    ${changeCell}
  </tr>`;
};

// Gerar linhas
const benchmarkRows = benchmarks.map(p => formatPriceRow(p)).join('');
const diffRows = differentials.map(p => formatDiffRow(p)).join('');

// Destaques (Lista com numeros em caixas pretas)
const destaquesHtml = destaques.map((d, i) => `
  <tr>
    <td style="padding-bottom: 15px;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr>
          <td width="30" valign="top">
            <div style="width: 24px; height: 24px; background: #000; color: #fff; text-align: center; line-height: 24px; font-family: ${STYLES.font}; font-size: 14px; font-weight: bold; border: 1px solid #000;">
                ${i + 1}
            </div>
          </td>
          <td style="font-family: ${STYLES.font}; font-size: 14px; color: #000; line-height: 1.4;">
            ${d}
          </td>
        </tr>
      </table>
    </td>
  </tr>
`).join('');

// Secao Baltic HTML
const balticSection = baltic ? `
  <!-- BALTIC FREIGHT INDICES -->
  <tr>
    <td style="padding: 0 30px 40px 30px;">
        <div style="border: ${STYLES.border}; background-color: #ffffff; box-shadow: ${STYLES.shadow};">
            <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="background-color: ${STYLES.accent}; padding: 10px; border-bottom: ${STYLES.border};">
                        <span style="font-family: ${STYLES.font}; font-size: 16px; font-weight: 900; text-transform: uppercase;">⚓ Baltic Freight Indices</span>
                    </td>
                </tr>
                <tr>
                    <td style="padding: 15px;">
                        <p style="margin: 0 0 10px 0; font-family: ${STYLES.font}; font-size: 11px; color: #666;">REPORT DATE: ${baltic.report_date || 'N/A'}</p>
                        <table width="100%" cellpadding="0" cellspacing="0">
                            <tbody>
                                ${formatBalticRow('BDI (Baltic Dry)', baltic.bdi)}
                                ${formatBalticRow('Capesize (BCI)', baltic.capesize)}
                                ${formatBalticRow('Panamax (BPI)', baltic.panamax)}
                                ${formatBalticRow('Supramax (BSI)', baltic.supramax)}
                                ${formatBalticRow('Handysize (BHSI)', baltic.handysize)}
                                
                                <!-- Rotas -->
                                <tr><td colspan="3" style="padding-top: 15px; font-weight: bold; font-family: ${STYLES.font}; font-size: 12px; text-decoration: underline;">KEY ROUTES ($/day)</td></tr>
                                ${formatBalticRow('C5TC (Aus-China)', baltic.c5tc)}
                                ${formatBalticRow('C3 (Bra-China)', baltic.c3)}
                                ${formatBalticRow('C5 (W.Aus-China)', baltic.c5)}
                            </tbody>
                        </table>
                    </td>
                </tr>
            </table>
        </div>
    </td>
  </tr>
` : '';

// --- TEMPLATE HTML COMPLETO ---
const html = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${subject}</title>
</head>
<body style="margin: 0; padding: 0; background-color: ${STYLES.bgPage}; font-family: ${STYLES.font}; color: ${STYLES.primary}; -webkit-font-smoothing: antialiased;">
  
  <center style="width: 100%; table-layout: fixed; background-color: ${STYLES.bgPage}; padding-bottom: 40px;">
    
    <table width="600" cellpadding="0" cellspacing="0" style="background-color: ${STYLES.bgContainer}; margin: 0 auto; width: 600px; max-width: 600px; border: 4px solid #000000; box-shadow: 10px 10px 0px #000000;">
          
      <!-- HEADER -->
      <tr>
        <td style="padding: 30px 30px 20px 30px; background-color: #ffffff;">
            <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td align="left" valign="bottom">
                        <img src="${LOGO_URL}" alt="MINERALS" width="200" style="max-width: 200px; height: auto; display: block;" />
                    </td>
                    <td align="right" valign="bottom">
                        <div style="border: 2px solid #000; padding: 4px 8px; display: inline-block; font-weight: bold; font-family: ${STYLES.font}; font-size: 11px; background: ${STYLES.accent}; box-shadow: 3px 3px 0px #000;">
                            DAILY REPORT
                        </div>
                    </td>
                </tr>
                <tr>
                    <td colspan="2" style="padding-top: 15px;">
                        <div style="height: 4px; background-color: #000000; width: 100%;"></div>
                    </td>
                </tr>
                <tr>
                    <td colspan="2" align="right" style="padding-top: 8px;">
                        <span style="font-family: ${STYLES.font}; font-size: 12px; background: #000; color: #fff; padding: 2px 6px;">
                            DATE: ${initData.date_display}
                        </span>
                    </td>
                </tr>
            </table>
        </td>
      </tr>

      <!-- HERO TITLE BLOCK (IRON ORE INSIGHTS) -->
      <tr>
        <td style="padding: 0 30px 30px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td style="font-family: ${STYLES.font}; font-size: 24px; font-weight: 900; line-height: 1; text-transform: uppercase; letter-spacing: -1px;">
                        IRON<br>
                        ORE<br>
                        <span style="background-color: ${STYLES.accent}; color: #ffffff; padding: 0 5px; box-shadow: 4px 4px 0px #000000; border: 2px solid #000; display: inline-block; margin-top: 5px;">INSIGHTS</span>
                    </td>
                    <td align="right" valign="bottom">
                        <p style="font-family: ${STYLES.font}; font-size: 11px; text-align: right; margin: 0;">
                            // GLOBAL MARKET<br>
                            // DAILY UPDATES
                        </p>
                    </td>
                </tr>
            </table>
        </td>
      </tr>

      <!-- IODEX HIGHLIGHT (Preco Destaque) -->
      <tr>
        <td style="padding: 0 30px 40px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0" style="border: ${STYLES.border}; background-color: #ffffff; box-shadow: ${STYLES.shadow};">
                <tr>
                    <td style="background-color: #000000; padding: 8px 15px; border-bottom: 3px solid #000000;">
                        <p style="font-family: ${STYLES.font}; font-size: 12px; color: ${STYLES.accent}; font-weight: bold; letter-spacing: 1px; margin: 0;">★ BENCHMARK HIGHLIGHT</p>
                    </td>
                </tr>
                <tr>
                    <td style="padding: 20px; background-color: #ffffff;">
                        <p style="font-family: ${STYLES.font}; font-size: 14px; margin: 0 0 5px 0; text-transform: uppercase; font-weight: bold;">IODEX CFR China 62% Fe</p>
                        <table width="100%" cellpadding="0" cellspacing="0">
                            <tr>
                                <td valign="middle">
                                    <span style="font-family: ${STYLES.font}; font-size: 42px; font-weight: 900; letter-spacing: -2px;">US$ ${iodexPrice}</span>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </td>
      </tr>

      <!-- BENCHMARK PRICES (Tabela) -->
      <tr>
        <td style="padding: 0 30px 40px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 10px;">
                <tr>
                    <td style="font-family: ${STYLES.font}; font-size: 16px; font-weight: 700; background: #000; color: #fff; padding: 5px 10px; display: inline-block;">
                        BENCHMARK PRICES
                    </td>
                </tr>
            </table>
            
            <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
                <thead>
                    <tr>
                        <th style="padding: 10px; border: 2px solid #000; background-color: #000; color: #fff; font-family: ${STYLES.font}; font-size: 13px; text-transform: uppercase; text-align: left;">INDICATOR</th>
                        <th style="padding: 10px; border: 2px solid #000; background-color: #000; color: #fff; font-family: ${STYLES.font}; font-size: 13px; text-transform: uppercase; text-align: right;">PRICE</th>
                        <th style="padding: 10px; border: 2px solid #000; background-color: #000; color: #fff; font-family: ${STYLES.font}; font-size: 13px; text-transform: uppercase; text-align: right;">CHG</th>
                    </tr>
                </thead>
                <tbody>
                    ${benchmarkRows}
                </tbody>
            </table>
        </td>
      </tr>

      <!-- QUALITY DIFFERENTIALS (Tabela) -->
      <tr>
        <td style="padding: 0 30px 40px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom: 10px;">
                <tr>
                    <td style="font-family: ${STYLES.font}; font-size: 16px; font-weight: 700; border: 2px solid #000; padding: 5px 10px; display: inline-block;">
                        QUALITY DIFFERENTIALS
                    </td>
                </tr>
            </table>
            
            <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
                <tbody>
                    ${diffRows}
                </tbody>
            </table>
        </td>
      </tr>

      ${balticSection}

      <!-- KEY HIGHLIGHTS -->
      <tr>
        <td style="padding: 40px 30px 40px 30px; background-color: #FDFBF7; border-top: 4px solid #000; border-bottom: 4px solid #000;">
            <h2 style="margin: 0 0 20px 0; font-family: ${STYLES.font}; font-size: 20px; font-weight: 900; text-transform: uppercase;">> KEY HIGHLIGHTS</h2>
            <table width="100%" cellpadding="0" cellspacing="0">
                ${destaquesHtml || '<tr><td>No highlights available</td></tr>'}
            </table>
        </td>
      </tr>

      <!-- MARKET RECAP -->
      <tr>
        <td style="padding: 40px 30px;">
            <h2 style="margin: 0 0 15px 0; font-family: ${STYLES.font}; font-size: 20px; font-weight: 900; border-left: 8px solid ${STYLES.accent}; padding-left: 15px; line-height: 1; text-transform: uppercase;">MARKET RECAP</h2>
            <p style="font-family: ${STYLES.font}; font-size: 14px; line-height: 1.6; text-align: justify;">
                ${resumo ? resumo.replace(/\n/g, '<br>') : 'Analysis not available.'}
            </p>
        </td>
      </tr>

      <!-- OUTLOOK -->
      <tr>
        <td style="padding: 0 30px 40px 30px;">
            <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td width="40" valign="top" style="padding-right: 10px;">
                        <div style="font-size: 30px;">🔮</div>
                    </td>
                    <td>
                        <h3 style="font-family: ${STYLES.font}; font-size: 16px; font-weight: 700; text-decoration: underline; margin: 0 0 10px 0; text-transform: uppercase;">OUTLOOK</h3>
                        <p style="font-family: ${STYLES.font}; font-size: 14px; font-style: italic; line-height: 1.5; margin: 0;">
                            "${perspectivas}"
                        </p>
                    </td>
                </tr>
            </table>
        </td>
      </tr>

      <!-- FOOTER -->
      <tr>
        <td style="background-color: #000000; color: #ffffff; padding: 30px;">
            <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                    <td align="center">
                        <p style="font-family: ${STYLES.font}; font-size: 24px; font-weight: 900; letter-spacing: 2px; margin: 0 0 10px 0;">MINERALS</p>
                        <p style="font-family: ${STYLES.font}; font-size: 12px; color: #888; margin: 0; text-transform: uppercase;">
                            TRADING | MINING | SERVICES
                        </p>
                        <div style="margin: 20px 0; border-top: 1px solid #333; width: 100px;"></div>
                        <p style="font-family: ${STYLES.font}; font-size: 12px; margin: 0;">
                            <a href="#" style="color: ${STYLES.accent}; text-decoration: none;">mineralstradingdaily.com.br</a>
                        </p>
                        <p style="font-family: ${STYLES.font}; font-size: 11px; margin: 20px 0 0 0; color: #555;">
                            © 2026 Minerals Trading. All rights reserved.
                        </p>
                    </td>
                </tr>
            </table>
        </td>
      </tr>

    </table>
  </center>
</body>
</html>`;

return [{
  json: {
    ...data,
    content_html: html,
    subject: subject,
    date_display: initData.date_display,
    session_id: initData.session_id
  }
}];

