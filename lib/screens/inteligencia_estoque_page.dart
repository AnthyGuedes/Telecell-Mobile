import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/app_database.dart';

class InteligenciaEstoquePage extends StatefulWidget {
  const InteligenciaEstoquePage({super.key});

  @override
  State<InteligenciaEstoquePage> createState() => _InteligenciaEstoquePageState();
}

class _InteligenciaEstoquePageState extends State<InteligenciaEstoquePage> {
  final AppDatabase _db = AppDatabase();
  bool _carregando = true;
  List<ModeloClassificado> _modelosClassificados = [];
  int _volumeTotal = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
    });

    try {
      final volumes = await _db.obterVolumePorModelo();
      final n = volumes.length;
      int totalVol = 0;
      for (var v in volumes) {
        totalVol += v.volume;
      }

      int runningSum = 0;
      final classificados = List.generate(n, (i) {
        final item = volumes[i];
        runningSum += item.volume;
        final double pctAcumulado = totalVol > 0 ? runningSum / totalVol : 0.0;

        String classe;
        Color cor;
        String descricaoRecomendacao;
        String acaoSugerida;

        // Se houver poucos modelos únicos cadastrados no banco de dados,
        // a lógica de porcentagem padrão pode classificar tudo como C.
        // Aplicamos uma regra simplificada para garantir uma divisão justa.
        if (n <= 3) {
          if (i == 0) {
            classe = 'A';
          } else if (i == 1) {
            classe = 'B';
          } else {
            classe = 'C';
          }
        } else {
          // Lógica da Curva ABC baseada no percentual acumulado do volume de OS
          // O modelo número 1 (mais frequente) é garantido no mínimo como Classe A ou B.
          if (i == 0) {
            classe = 'A';
          } else if (pctAcumulado <= 0.20) {
            classe = 'A';
          } else if (pctAcumulado <= 0.50) {
            classe = 'B';
          } else {
            classe = 'C';
          }
        }

        if (classe == 'A') {
          cor = const Color(0xFFE67E22); // Laranja (Alta Rotatividade)
          acaoSugerida = 'Lote Fechado / Estoque de Segurança';
          descricaoRecomendacao = 'Compre telas, baterias e conectores em lote para obter descontos no atacado e garantir atendimento rápido. Este modelo representa alta rotatividade.';
        } else if (classe == 'B') {
          cor = const Color(0xFF1565C0); // Azul (Média Rotatividade)
          acaoSugerida = 'Estoque Controlado / Reposição Semanal';
          descricaoRecomendacao = 'Mantenha um estoque mínimo (1 a 2 unidades de baterias/telas). Compre reposições assim que as peças forem sendo utilizadas.';
        } else {
          cor = const Color(0xFF7F8C8D); // Cinza (Baixa Rotatividade)
          acaoSugerida = 'Just-in-Time (Sob Demanda)';
          descricaoRecomendacao = 'Não compre peças para estoque. Adquira peças originais apenas após a OS ser aberta e o orçamento aprovado pelo cliente.';
        }

        return ModeloClassificado(
          marcaModelo: item.marcaModelo,
          volume: item.volume,
          classe: classe,
          cor: cor,
          acaoSugerida: acaoSugerida,
          descricaoRecomendacao: descricaoRecomendacao,
        );
      });

      if (!mounted) return;

      setState(() {
        _modelosClassificados = classificados;
        _volumeTotal = totalVol;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao calcular Inteligência de Estoque: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Inteligência de Estoque'),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _modelosClassificados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Sem Ordens de Serviço cadastradas para realizar a análise.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Resumo das Métricas
                        _buildResumoCard(),
                        const SizedBox(height: 20),

                        // Card do Gráfico
                        _buildGraficoCard(),
                        const SizedBox(height: 24),

                        // Título das Sugestões
                        const Text(
                          'Sugestões de Compra por Modelo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Lista detalhada de Recomendações
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _modelosClassificados.length,
                          itemBuilder: (context, index) {
                            final model = _modelosClassificados[index];
                            return _buildRecomendacaoCard(model);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildResumoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'Total de Modelos',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _modelosClassificados.length.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
              ],
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            Column(
              children: [
                const Text(
                  'Volume Total OS',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _volumeTotal.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraficoCard() {
    // Pegar o máximo volume para escala Y
    final double maxVolume = _modelosClassificados.map((m) => m.volume).reduce((a, b) => a > b ? a : b).toDouble();

    // Limitar para exibir no máximo top 8 no gráfico para não amontoar
    final numExibidos = _modelosClassificados.length > 8 ? 8 : _modelosClassificados.length;
    final dataExibida = _modelosClassificados.sublist(0, numExibidos);

    List<BarChartGroupData> barGroups = List.generate(dataExibida.length, (i) {
      final model = dataExibida[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: model.volume.toDouble(),
            color: model.cor,
            width: 18,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          )
        ],
      );
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Volume de Entradas por Modelo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 6),
            Text(
              'Exibindo os ${dataExibida.length} modelos mais frequentes',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVolume + 2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF2C3E50).withValues(alpha: 0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final model = dataExibida[groupIndex];
                        return BarTooltipItem(
                          '${model.marcaModelo}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: 'Volume: ${rod.toY.toInt()}\nClasse: ${model.classe}',
                              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dataExibida.length) return const SizedBox.shrink();
                          final label = dataExibida[index].marcaModelo;
                          // Divide a string para pegar o modelo (última palavra ou segunda)
                          final parts = label.split(' ');
                          final displayLabel = parts.length > 1 ? parts.sublist(1).join(' ') : label;

                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Transform.rotate(
                              angle: -0.2, // Rotação leve para caber melhor
                              child: Text(
                                displayLabel,
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF5A6B7C)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legenda do gráfico
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendaItem('Classe A', const Color(0xFFE67E22)),
                const SizedBox(width: 24),
                _buildLegendaItem('Classe B', const Color(0xFF1565C0)),
                const SizedBox(width: 24),
                _buildLegendaItem('Classe C', const Color(0xFF7F8C8D)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5A6B7C)),
        ),
      ],
    );
  }

  Widget _buildRecomendacaoCard(ModeloClassificado model) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: model.cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Classe ${model.classe}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: model.cor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.marcaModelo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '${model.volume} OS',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    model.acaoSugerida,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: model.cor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.descricaoRecomendacao,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModeloClassificado {
  final String marcaModelo;
  final int volume;
  final String classe;
  final Color cor;
  final String acaoSugerida;
  final String descricaoRecomendacao;

  ModeloClassificado({
    required this.marcaModelo,
    required this.volume,
    required this.classe,
    required this.cor,
    required this.acaoSugerida,
    required this.descricaoRecomendacao,
  });
}
