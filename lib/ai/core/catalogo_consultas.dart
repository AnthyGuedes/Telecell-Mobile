/// ============================================================================
/// CATÁLOGO DE CONSULTAS CURADAS + ROTEADOR DETERMINÍSTICO
/// ----------------------------------------------------------------------------
/// Por que isto existe: um SLM de 1B–4B parâmetros erra Text-to-SQL livre com
/// frequência alta. Mas ~80% das perguntas reais de uma assistência técnica são
/// as mesmas oito. Este roteador resolve essas oito por casamento de palavras —
/// sem inferência, resposta em milissegundos, SQL escrito e revisado por humano.
///
/// O modelo local só é acionado nas perguntas novas. Resultado: latência baixa
/// no caso comum e menor superfície de erro no caso raro.
/// ============================================================================
library;

class ConsultaCurada {
  final String id;
  final String titulo;
  final String sql;
  final List<String> gatilhos;

  const ConsultaCurada({
    required this.id,
    required this.titulo,
    required this.sql,
    required this.gatilhos,
  });
}

class CatalogoConsultas {
  CatalogoConsultas._();

  static const List<ConsultaCurada> consultas = [
    ConsultaCurada(
      id: 'faturamento_30d',
      titulo: 'Faturamento e ticket médio (30 dias)',
      gatilhos: ['faturamento', 'faturei', 'receita', 'quanto ganhei',
        'ticket medio', 'ticket médio', 'fatura'],
      sql: '''
SELECT
  COUNT(*)                              AS ordens_finalizadas,
  ROUND(SUM(COALESCE(valor, 0)), 2)     AS faturamento_total,
  ROUND(AVG(COALESCE(valor, 0)), 2)     AS ticket_medio
FROM ordens_servico
WHERE tipo_registro = 'OS'
  AND status IN ('Concluído', 'Concluída', 'Aguardando Retirada')
  AND data_entrada >= CAST(strftime('%s', 'now', '-30 days') AS INTEGER)''',
    ),
    ConsultaCurada(
      id: 'volume_por_status',
      titulo: 'Distribuição de ordens por status',
      gatilhos: ['status', 'quantas ordens', 'pendente', 'em manutencao',
        'em manutenção', 'situacao', 'situação'],
      sql: '''
SELECT status, COUNT(*) AS quantidade
FROM ordens_servico
GROUP BY status
ORDER BY quantidade DESC''',
    ),
    ConsultaCurada(
      id: 'gargalo_operacional',
      titulo: 'Gargalos: ordens paradas e tempo médio em aberto',
      gatilhos: ['gargalo', 'parada', 'paradas', 'atrasada', 'atrasadas',
        'tempo medio', 'tempo médio', 'demorando', 'travada'],
      sql: '''
SELECT
  status,
  COUNT(*) AS quantidade,
  ROUND(AVG((CAST(strftime('%s','now') AS INTEGER) - data_entrada) / 86400.0), 1)
    AS dias_medios_em_aberto
FROM ordens_servico
WHERE status NOT IN ('Concluído', 'Concluída')
GROUP BY status
ORDER BY dias_medios_em_aberto DESC''',
    ),
    ConsultaCurada(
      id: 'modelos_recorrentes',
      titulo: 'Aparelhos mais atendidos e receita por modelo',
      gatilhos: ['modelo', 'modelos', 'aparelho', 'aparelhos', 'consertamos',
        'mais atendido', 'curva abc', 'estoque'],
      sql: '''
SELECT
  marca_modelo,
  COUNT(*)                          AS volume,
  ROUND(SUM(COALESCE(valor, 0)), 2) AS receita
FROM ordens_servico
GROUP BY marca_modelo
ORDER BY volume DESC
LIMIT 10''',
    ),
    ConsultaCurada(
      id: 'top_clientes',
      titulo: 'Clientes que mais geraram receita',
      gatilhos: ['melhor cliente', 'melhores clientes', 'top clientes',
        'cliente que mais', 'clientes que mais', 'quem mais gastou'],
      sql: '''
SELECT
  c.nome,
  COUNT(o.id)                         AS atendimentos,
  ROUND(SUM(COALESCE(o.valor, 0)), 2) AS total_gasto
FROM ordens_servico o
INNER JOIN clientes c ON c.id = o.cliente_id
GROUP BY c.id, c.nome
ORDER BY total_gasto DESC
LIMIT 10''',
    ),
    ConsultaCurada(
      id: 'conversao_orcamento',
      titulo: 'Ordens de serviço x orçamentos',
      gatilhos: ['orcamento', 'orçamento', 'orcamentos', 'orçamentos',
        'conversao', 'conversão', 'aprovacao', 'aprovação'],
      sql: '''
SELECT
  tipo_registro,
  COUNT(*)                          AS quantidade,
  ROUND(SUM(COALESCE(valor, 0)), 2) AS valor_total
FROM ordens_servico
GROUP BY tipo_registro''',
    ),
    ConsultaCurada(
      id: 'serie_mensal',
      titulo: 'Evolução mensal de volume e faturamento',
      gatilhos: ['por mes', 'por mês', 'mensal', 'evolucao', 'evolução',
        'historico', 'histórico', 'crescimento', 'ultimos meses',
        'últimos meses'],
      sql: '''
SELECT
  strftime('%Y-%m', data_entrada, 'unixepoch', 'localtime') AS mes,
  COUNT(*)                          AS ordens,
  ROUND(SUM(COALESCE(valor, 0)), 2) AS faturamento
FROM ordens_servico
GROUP BY mes
ORDER BY mes DESC
LIMIT 12''',
    ),
    ConsultaCurada(
      id: 'problemas_recorrentes',
      titulo: 'Defeitos mais relatados pelos clientes',
      gatilhos: ['problema', 'problemas', 'defeito', 'defeitos', 'reclamacao',
        'reclamação', 'sintoma', 'mais comum'],
      sql: '''
SELECT
  TRIM(SUBSTR(problema_relatado, 1, 60)) AS problema,
  COUNT(*)                               AS ocorrencias
FROM ordens_servico
GROUP BY LOWER(TRIM(SUBSTR(problema_relatado, 1, 60)))
ORDER BY ocorrencias DESC
LIMIT 10''',
    ),
  ];

  /// Perguntas sugeridas na tela do analista (empty state acionável).
  static List<String> get sugestoes => const [
        'Qual foi meu faturamento nos últimos 30 dias?',
        'Quais modelos eu mais conserto?',
        'Onde está o gargalo da oficina hoje?',
        'Quem são meus melhores clientes?',
      ];

  /// Tenta resolver a pergunta sem acionar o modelo.
  /// Retorna `null` quando nenhuma curada tem confiança suficiente.
  static ConsultaCurada? rotear(String pergunta) {
    final normalizada = _normalizar(pergunta);

    ConsultaCurada? melhor;
    var melhorPontuacao = 0;

    for (final consulta in consultas) {
      var pontuacao = 0;
      for (final gatilho in consulta.gatilhos) {
        if (normalizada.contains(_normalizar(gatilho))) {
          // Gatilhos mais longos são mais específicos e valem mais.
          pontuacao += gatilho.length;
        }
      }
      if (pontuacao > melhorPontuacao) {
        melhorPontuacao = pontuacao;
        melhor = consulta;
      }
    }

    // Piso de confiança: evita casar "os" em qualquer frase.
    return melhorPontuacao >= 6 ? melhor : null;
  }

  static String _normalizar(String texto) {
    const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const semAcento = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final buffer = StringBuffer();
    for (final char in texto.toLowerCase().split('')) {
      final idx = comAcento.indexOf(char);
      buffer.write(idx >= 0 ? semAcento[idx].toLowerCase() : char);
    }
    return buffer.toString();
  }
}
