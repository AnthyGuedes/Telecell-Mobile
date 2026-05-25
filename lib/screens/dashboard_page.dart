import 'package:flutter/material.dart';
import '../database/app_database.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AppDatabase _db = AppDatabase();
  final TextEditingController _searchController = TextEditingController();
  
  List<OrdemComCliente> _todasAsOrdens = [];
  List<OrdemComCliente> _ordensFiltradas = [];
  bool _carregando = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
    });
    try {
      final ordens = await _db.listarOrdensComCliente();
      if (!mounted) return;
      setState(() {
        _todasAsOrdens = ordens;
        _filtrarOrdens(_searchQuery);
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e')),
      );
    }
  }

  void _filtrarOrdens(String query) {
    if (query.isEmpty) {
      setState(() {
        _ordensFiltradas = [];
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _ordensFiltradas = _todasAsOrdens.where((item) {
        final nomeMatch = item.cliente.nome.toLowerCase().contains(lowerQuery);
        final cpfMatch = item.cliente.cpf.replaceAll(RegExp(r'\D'), '').contains(lowerQuery) || 
                         item.cliente.cpf.toLowerCase().contains(lowerQuery);
        final cpfOsMatch = item.ordem.imei.toLowerCase().contains(lowerQuery);
        final modeloMatch = item.ordem.marcaModelo.toLowerCase().contains(lowerQuery);
        final idMatch = item.ordem.id.toString() == lowerQuery || '#${item.ordem.id}' == lowerQuery;
        
        return nomeMatch || cpfMatch || cpfOsMatch || modeloMatch || idMatch;
      }).toList();

      // Ordenação alfabética pelo nome do cliente (A-Z)
      _ordensFiltradas.sort((a, b) => a.cliente.nome.toLowerCase().compareTo(b.cliente.nome.toLowerCase()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Contagem de status baseada nos dados atuais
    int total = _todasAsOrdens.length;
    int pendente = _todasAsOrdens.where((o) => o.ordem.status == 'Pendente' || o.ordem.status == 'Aberta').length;
    int emManutencao = _todasAsOrdens.where((o) => o.ordem.status == 'Em Manutenção').length;
    int aguardandoConf = _todasAsOrdens.where((o) => o.ordem.status == 'Aguardo de confirmação' || o.ordem.status == 'Aguardando Confirmação').length;
    int concluido = _todasAsOrdens.where((o) => o.ordem.status == 'Concluído' || o.ordem.status == 'Concluída').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.phonelink_setup, size: 28),
            SizedBox(width: 10),
            Text(
              'Telecell Mobile',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDados,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: _carregando 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho azul com gradiente e barra de pesquisa
                    _buildHeader(),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _searchQuery.isNotEmpty
                            ? _buildSearchResults()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Seção de Contadores/Métricas
                                  const Text(
                                    'Visão Geral dos Serviços',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMetricsGrid(total, pendente, emManutencao, aguardandoConf, concluido),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Seção de Atalhos / Quick Actions
                                  const Text(
                                    'Ações Rápidas',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildQuickActionsGrid(),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Seção de Destaque / Banner Informativo
                                  _buildWelcomeBanner(),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
      ),
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olá, Técnico!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gerencie ordens de serviço e orçamentos com facilidade.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[100],
            ),
          ),
          const SizedBox(height: 22),
          // Barra de pesquisa com design premium
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
                _filtrarOrdens(val);
              },
              decoration: InputDecoration(
                hintText: 'Buscar por Nome, CPF, Modelo ou OS ID...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _filtrarOrdens('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(int total, int pendente, int emManutencao, int aguardandoConf, int concluido) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'Total Geral',
          total.toString(),
          Icons.assessment,
          const [Color(0xFF2C3E50), Color(0xFF34495E)],
          onTap: () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: {
              'tabIndex': 0,
              'statusFilter': 'Todos',
            });
            _carregarDados();
          },
        ),
        _buildMetricCard(
          'Pendentes',
          pendente.toString(),
          Icons.pending_actions,
          const [Color(0xFFE67E22), Color(0xFFD35400)],
          onTap: () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: {
              'tabIndex': 0,
              'statusFilter': 'Pendente',
            });
            _carregarDados();
          },
        ),
        _buildMetricCard(
          'Em Manutenção',
          emManutencao.toString(),
          Icons.build,
          const [Color(0xFF2980B9), Color(0xFF1F3A60)],
          onTap: () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: {
              'tabIndex': 0,
              'statusFilter': 'Em Manutenção',
            });
            _carregarDados();
          },
        ),
        _buildMetricCard(
          'Aguardando Conf.',
          aguardandoConf.toString(),
          Icons.lock_clock,
          const [Color(0xFF8E44AD), Color(0xFF9B59B6)],
          onTap: () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: {
              'tabIndex': 0,
              'statusFilter': 'Aguardo de confirmação',
            });
            _carregarDados();
          },
        ),
        _buildMetricCard(
          'Concluídos',
          concluido.toString(),
          Icons.check_circle,
          const [Color(0xFF27AE60), Color(0xFF2ECC71)],
          isFullWidth: true,
          onTap: () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: {
              'tabIndex': 0,
              'statusFilter': 'Concluído',
            });
            _carregarDados();
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, List<Color> colors, {bool isFullWidth = false, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                color: Colors.white30,
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildActionButton(
          'Nova OS',
          'Serviço Imediato',
          Icons.add_circle_outline,
          const Color(0xFF1565C0),
          () async {
            await Navigator.pushNamed(context, '/cadastro-os', arguments: 'OS');
            _carregarDados();
          },
        ),
        _buildActionButton(
          'Novo Orçamento',
          'Criar Novo OC',
          Icons.assignment_outlined,
          const Color(0xFF00897B),
          () async {
            await Navigator.pushNamed(context, '/cadastro-os', arguments: 'Orçamento');
            _carregarDados();
          },
        ),
        _buildActionButton(
          'Serviços',
          'Listar Todos',
          Icons.format_list_bulleted,
          const Color(0xFF37474F),
          () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: 0);
            _carregarDados();
          },
        ),
        _buildActionButton(
          'Clientes',
          'Gerenciar Clientes',
          Icons.people_outline,
          const Color(0xFF5D4037),
          () async {
            await Navigator.pushNamed(context, '/lista-ordens', arguments: 1);
            _carregarDados();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15), width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dica de Produtividade',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Utilize a pesquisa rápida para localizar clientes e aparelhos instantaneamente sem navegar.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_ordensFiltradas.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Nenhum resultado encontrado para "$_searchQuery"',
              style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Verifique o termo digitado ou cadastre um novo serviço.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resultados da busca (${_ordensFiltradas.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _filtrarOrdens('');
              },
              child: const Text('Limpar busca'),
            )
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ordensFiltradas.length,
          itemBuilder: (context, index) {
            final item = _ordensFiltradas[index];
            return _buildResultCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildResultCard(OrdemComCliente item) {
    Color statusColor;
    switch (item.ordem.status.toLowerCase()) {
      case 'pendente':
      case 'aberta':
        statusColor = const Color(0xFFE67E22);
        break;
      case 'em manutenção':
      case 'em manutencao':
        statusColor = const Color(0xFF2980B9);
        break;
      case 'aguardo de confirmação':
      case 'aguardo de confirmacao':
      case 'aguardando confirmação':
        statusColor = const Color(0xFF8E44AD);
        break;
      case 'concluído':
      case 'concluida':
      case 'concluido':
        statusColor = const Color(0xFF27AE60);
        break;
      default:
        statusColor = Colors.grey;
    }

    final isOrcamento = item.ordem.tipoRegistro.toLowerCase().contains('orç') || 
                        item.ordem.tipoRegistro.toLowerCase().contains('orc');

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.pushNamed(
            context, 
            '/detalhes-os', 
            arguments: item,
          );
          _carregarDados();
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOrcamento ? const Color(0xFF00897B).withValues(alpha: 0.1) : const Color(0xFF1565C0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOrcamento ? 'Orçamento (OC)' : 'Ordem Serviço (OS)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOrcamento ? const Color(0xFF00897B) : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${item.ordem.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F8C8D),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.ordem.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.ordem.marcaModelo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    item.cliente.nome,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_cell, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'CPF: ${item.ordem.imei}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if (item.ordem.valor != null)
                    Text(
                      'R\$ ${item.ordem.valor!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    )
                  else
                    Text(
                      'R\$ 0,00',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
