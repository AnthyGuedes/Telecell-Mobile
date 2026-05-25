import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class ListaOrdensPage extends StatefulWidget {
  const ListaOrdensPage({super.key});

  @override
  State<ListaOrdensPage> createState() => _ListaOrdensPageState();
}

class _ListaOrdensPageState extends State<ListaOrdensPage> with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  late TabController _tabController;
  
  // Dados de Ordens
  List<OrdemComCliente> _todasAsOrdens = [];
  List<OrdemComCliente> _ordensExibidas = [];
  bool _carregandoOrdens = true;
  String _filtroStatus = 'Todos';
  String _filtroTipo = 'Todos';
  String _buscaOrdemQuery = '';

  // Dados de Clientes
  List<Cliente> _todosOsClientes = [];
  List<Cliente> _clientesExibidos = [];
  bool _carregandoClientes = true;
  String _buscaClienteQuery = '';

  @override
  void initState() {
    super.initState();
    // A aba padrão será definida no didChangeDependencies caso seja passado algum argumento
    _tabController = TabController(length: 2, vsync: this);
    _carregarOrdens();
    _carregarClientes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captura aba inicial se passada por argumento (0: ordens, 1: clientes)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _tabController.index = args;
    } else if (args is Map<String, dynamic>) {
      _tabController.index = args['tabIndex'] ?? 0;
      if (args['statusFilter'] != null) {
        _filtroStatus = args['statusFilter'];
        _aplicarFiltrosOrdens();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarOrdens() async {
    setState(() {
      _carregandoOrdens = true;
    });
    try {
      final ordens = await _db.listarOrdensComCliente();
      setState(() {
        _todasAsOrdens = ordens;
        _aplicarFiltrosOrdens();
        _carregandoOrdens = false;
      });
    } catch (e) {
      setState(() {
        _carregandoOrdens = false;
      });
      _mostrarMensagem('Erro ao carregar ordens: $e');
    }
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _carregandoClientes = true;
    });
    try {
      final clientes = await _db.listarClientes();
      setState(() {
        _todosOsClientes = clientes;
        _filtrarClientes(_buscaClienteQuery);
        _carregandoClientes = false;
      });
    } catch (e) {
      setState(() {
        _carregandoClientes = false;
      });
      _mostrarMensagem('Erro ao carregar clientes: $e');
    }
  }

  void _aplicarFiltrosOrdens() {
    setState(() {
      _ordensExibidas = _todasAsOrdens.where((item) {
        // Filtro por busca de texto
        final query = _buscaOrdemQuery.toLowerCase();
        final matchBusca = query.isEmpty ||
            item.cliente.nome.toLowerCase().contains(query) ||
            item.cliente.cpf.toLowerCase().contains(query) ||
            item.ordem.imei.toLowerCase().contains(query) ||
            item.ordem.marcaModelo.toLowerCase().contains(query) ||
            '#${item.ordem.id}' == query ||
            item.ordem.id.toString() == query;

        // Filtro de Status
        bool matchStatus = true;
        if (_filtroStatus != 'Todos') {
          if (_filtroStatus == 'Pendente') {
            matchStatus = item.ordem.status == 'Pendente' || item.ordem.status == 'Aberta';
          } else {
            matchStatus = item.ordem.status == _filtroStatus;
          }
        }

        // Filtro de Tipo (OS ou Orçamento)
        bool matchTipo = true;
        if (_filtroTipo != 'Todos') {
          final isOrcamento = item.ordem.tipoRegistro.toLowerCase().contains('orç') || 
                             item.ordem.tipoRegistro.toLowerCase().contains('orc');
          if (_filtroTipo == 'OS') {
            matchTipo = !isOrcamento;
          } else if (_filtroTipo == 'Orçamento') {
            matchTipo = isOrcamento;
          }
        }

        return matchBusca && matchStatus && matchTipo;
      }).toList();

      // Ordenação alfabética pelo nome do cliente (A-Z)
      _ordensExibidas.sort((a, b) => a.cliente.nome.toLowerCase().compareTo(b.cliente.nome.toLowerCase()));
    });
  }

  void _filtrarClientes(String query) {
    setState(() {
      _buscaClienteQuery = query;
      if (query.isEmpty) {
        _clientesExibidos = List.from(_todosOsClientes);
      } else {
        final lower = query.toLowerCase();
        _clientesExibidos = _todosOsClientes.where((c) {
          return c.nome.toLowerCase().contains(lower) ||
              c.cpf.toLowerCase().contains(lower) ||
              c.telefone.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // Abre janela para criar um novo cliente
  void _mostrarDialogoCriarCliente() {
    final nomeController = TextEditingController();
    final cpfController = TextEditingController();
    final telefoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1565C0)),
              SizedBox(width: 10),
              Text('Novo Cliente'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '(DD) 9XXXX-XXXX',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Telefone é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      prefixIcon: Icon(Icons.badge),
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'CPF é obrigatório' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final novoCliente = ClientesCompanion(
                    nome: drift.Value(nomeController.text.trim()),
                    telefone: drift.Value(telefoneController.text.trim()),
                    cpf: drift.Value(cpfController.text.trim()),
                  );
                  try {
                    await _db.inserirCliente(novoCliente);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _mostrarMensagem('Cliente cadastrado com sucesso!');
                    _carregarClientes();
                  } catch (e) {
                    if (!context.mounted) return;
                    _mostrarMensagem('Erro ao cadastrar: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Abre janela para editar cliente
  void _mostrarDialogoEditarCliente(Cliente cliente) {
    final nomeController = TextEditingController(text: cliente.nome);
    final cpfController = TextEditingController(text: cliente.cpf);
    final telefoneController = TextEditingController(text: cliente.telefone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF1565C0)),
              SizedBox(width: 10),
              Text('Editar Cliente'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v == null || v.isEmpty ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telefoneController,
                    decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Telefone é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cpfController,
                    decoration: const InputDecoration(labelText: 'CPF', prefixIcon: Icon(Icons.badge)),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'CPF é obrigatório' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final clienteAtualizado = Cliente(
                    id: cliente.id,
                    nome: nomeController.text.trim(),
                    telefone: telefoneController.text.trim(),
                    cpf: cpfController.text.trim(),
                  );
                  try {
                    await _db.atualizarCliente(clienteAtualizado);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _mostrarMensagem('Cliente atualizado!');
                    _carregarClientes();
                    _carregarOrdens(); // Atualiza também ordens, pois o nome do cliente pode ter mudado
                  } catch (e) {
                    if (!context.mounted) return;
                    _mostrarMensagem('Erro ao atualizar: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Deleta o cliente (se não houver ordens vinculadas, ou confirma)
  void _excluirCliente(Cliente cliente) async {
    final ordens = await _db.listarOrdensPorCliente(cliente.id);
    if (!mounted) return;
    if (ordens.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ação Impedida'),
          content: Text(
            'Não é possível excluir o cliente ${cliente.nome} porque ele possui ${ordens.length} ordens de serviço ativas no histórico. Exclua as ordens de serviço primeiro.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            )
          ],
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir o cliente ${cliente.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmar == true) {
      try {
        await _db.excluirCliente(cliente.id);
        if (!mounted) return;
        _mostrarMensagem('Cliente excluído!');
        _carregarClientes();
      } catch (e) {
        if (!mounted) return;
        _mostrarMensagem('Erro ao excluir cliente: $e');
      }
    }
  }

  // Exibe o histórico de Ordens de Serviço vinculadas ao cliente (Relação 1:N)
  void _mostrarHistoricoCliente(Cliente cliente) async {
    setState(() {
      _carregandoClientes = true;
    });
    
    try {
      final ordens = await _db.listarOrdensPorCliente(cliente.id);
      if (!mounted) return;
      setState(() {
        _carregandoClientes = false;
      });

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Barra de arrasto visual
                const SizedBox(height: 12),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 16),
                
                // Detalhes do Cliente
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: Color(0xFF1565C0), size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cliente.nome,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CPF: ${cliente.cpf} • Tel: ${cliente.telefone}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                
                // Cabeçalho Histórico
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Histórico de Serviços (1:N)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '${ordens.length} registro(s)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de Ordens
                Expanded(
                  child: ordens.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assignment_turned_in, size: 54, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Nenhum serviço registrado para este cliente.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: ordens.length,
                          itemBuilder: (context, index) {
                            final ordem = ordens[index];
                            
                            Color statusColor;
                            switch (ordem.status.toLowerCase()) {
                              case 'pendente':
                              case 'aberta':
                                statusColor = const Color(0xFFE67E22);
                                break;
                              case 'em manutenção':
                                statusColor = const Color(0xFF2980B9);
                                break;
                              case 'aguardo de confirmação':
                                statusColor = const Color(0xFF8E44AD);
                                break;
                              case 'concluído':
                                statusColor = const Color(0xFF27AE60);
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            final isOrc = ordem.tipoRegistro.toLowerCase().contains('orç') ||
                                          ordem.tipoRegistro.toLowerCase().contains('orc');

                            return Card(
                              color: Colors.white,
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                title: Text(ordem.marcaModelo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('CPF: ${ordem.imei}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Entrada: ${ordem.dataEntrada.day.toString().padLeft(2, '0')}/${ordem.dataEntrada.month.toString().padLeft(2, '0')}/${ordem.dataEntrada.year}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                      child: Text(ordem.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ordem.valor != null ? 'R\$ ${ordem.valor!.toStringAsFixed(2)}' : 'Orçamento',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isOrc ? const Color(0xFF00897B) : const Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(context); // fecha bottom sheet
                                  Navigator.pushNamed(
                                    context, 
                                    '/detalhes-os', 
                                    arguments: OrdemComCliente(ordem: ordem, cliente: cliente),
                                  ).then((_) {
                                    _carregarOrdens();
                                    _carregarClientes();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _carregandoClientes = false;
      });
      _mostrarMensagem('Erro ao carregar histórico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Gerenciador Telecell', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.blue[100],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Serviços & Orçamentos'),
            Tab(icon: Icon(Icons.people), text: 'Nossos Clientes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _carregarOrdens();
              _carregarClientes();
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ABA 1: SERVIÇOS & ORÇAMENTOS
          _buildServicosTab(),
          
          // ABA 2: CLIENTES
          _buildClientesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Nova OS
            Navigator.pushNamed(context, '/cadastro-os', arguments: 'OS').then((_) => _carregarOrdens());
          } else {
            // Novo Cliente
            _mostrarDialogoCriarCliente();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildServicosTab() {
    if (_carregandoOrdens) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Barra de Pesquisa de Ordens
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _buscaOrdemQuery = val;
                });
                _aplicarFiltrosOrdens();
              },
              decoration: const InputDecoration(
                hintText: 'Pesquisar ordem por nome, modelo, CPF ou #ID...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1565C0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        
        // Filtros (Tipo e Status)
        _buildFiltrosBar(),

        // Lista de Ordens
        Expanded(
          child: _ordensExibidas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.layers_clear_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Nenhuma ordem de serviço encontrada.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: _ordensExibidas.length,
                  itemBuilder: (context, index) {
                    final item = _ordensExibidas[index];
                    return _buildOrdemCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltrosBar() {
    final statusList = ['Todos', 'Pendente', 'Em Manutenção', 'Aguardo de confirmação', 'Concluído'];
    final tiposList = ['Todos', 'OS', 'Orçamento'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtro por Tipo
          Row(
            children: [
              Text('Tipo:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: tiposList.map((tipo) {
                      final isSelected = _filtroTipo == tipo;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(tipo, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _filtroTipo = tipo;
                              });
                              _aplicarFiltrosOrdens();
                            }
                          },
                          selectedColor: const Color(0xFF1565C0),
                          backgroundColor: const Color(0xFFF1F3F5),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Filtro por Status
          Row(
            children: [
              Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: statusList.map((status) {
                      final isSelected = _filtroStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(status, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _filtroStatus = status;
                              });
                              _aplicarFiltrosOrdens();
                            }
                          },
                          selectedColor: const Color(0xFFE67E22),
                          backgroundColor: const Color(0xFFF1F3F5),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdemCard(OrdemComCliente item) {
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
      case 'concluido':
      case 'concluida':
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
        onTap: () {
          Navigator.pushNamed(context, '/detalhes-os', arguments: item).then((_) => _carregarOrdens());
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
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
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.ordem.marcaModelo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    item.cliente.nome,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  Text(
                    item.ordem.valor != null ? 'R\$ ${item.ordem.valor!.toStringAsFixed(2)}' : 'A definir',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.ordem.valor != null ? const Color(0xFF2C3E50) : Colors.grey[400],
                      fontStyle: item.ordem.valor != null ? FontStyle.normal : FontStyle.italic,
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

  Widget _buildClientesTab() {
    if (_carregandoClientes) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Pesquisa de Clientes
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: _filtrarClientes,
              decoration: const InputDecoration(
                hintText: 'Pesquisar cliente por nome, telefone ou CPF...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1565C0)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Lista de Clientes
        Expanded(
          child: _clientesExibidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Nenhum cliente cadastrado.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  itemCount: _clientesExibidos.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientesExibidos[index];
                    return Card(
                      color: Colors.white,
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF1565C0),
                          child: Text(cliente.nome.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Tel: ${cliente.telefone}', style: const TextStyle(fontSize: 12)),
                            Text('CPF: ${cliente.cpf}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () => _mostrarDialogoEditarCliente(cliente),
                              tooltip: 'Editar dados',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _excluirCliente(cliente),
                              tooltip: 'Excluir cliente',
                            ),
                          ],
                        ),
                        onTap: () => _mostrarHistoricoCliente(cliente),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
