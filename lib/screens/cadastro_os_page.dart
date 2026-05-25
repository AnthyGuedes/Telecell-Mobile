import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class CadastroOsPage extends StatefulWidget {
  const CadastroOsPage({super.key});

  @override
  State<CadastroOsPage> createState() => _CadastroOsPageState();
}

class _CadastroOsPageState extends State<CadastroOsPage> {
  final AppDatabase _db = AppDatabase();
  final _formKey = GlobalKey<FormState>();

  // Controladores do Formulário
  String _tipoRegistro = 'OS'; // 'OS' ou 'Orçamento'
  Cliente? _clienteSelecionado;
  OrdemDeServico? _ultimaOrdemCliente; // Para auto-preenchimento
  
  final _marcaModeloController = TextEditingController();
  final _corController = TextEditingController();
  String _armazenamento = '128GB';
  final _senhaController = TextEditingController();
  final _problemaController = TextEditingController();
  
  bool _displayOk = true;
  bool _touchOk = true;

  // Novos campos de Acessórios
  bool _chipOk = false;
  bool _peliculaOk = false;
  bool _capinhaOk = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captura o argumento inicial de Tipo de Registro (OS ou Orçamento)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      setState(() {
        _tipoRegistro = args;
      });
    }
  }

  @override
  void dispose() {
    _marcaModeloController.dispose();
    _corController.dispose();
    _senhaController.dispose();
    _problemaController.dispose();
    super.dispose();
  }

  // Busca e verifica se o cliente possui ordens anteriores para sugerir auto-preenchimento
  Future<void> _verificarUltimoAparelho(Cliente cliente) async {
    try {
      final ordens = await _db.listarOrdensPorCliente(cliente.id);
      if (ordens.isNotEmpty) {
        setState(() {
          _ultimaOrdemCliente = ordens.first; // A mais recente (ordenada por data decrescente no DB)
        });
      } else {
        setState(() {
          _ultimaOrdemCliente = null;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar último aparelho: $e');
    }
  }

  // Preenche automaticamente os campos com base na última OS do cliente
  void _preencherComUltimoAparelho() {
    if (_ultimaOrdemCliente == null) return;
    
    final marcaModeloStr = _ultimaOrdemCliente!.marcaModelo;
    
    // Parser amigável do modelo: ex "iPhone 13 - Azul (128GB)"
    String model = marcaModeloStr;
    String color = '';
    String storage = '128GB';

    if (marcaModeloStr.contains('(') && marcaModeloStr.contains(')')) {
      final startIdx = marcaModeloStr.indexOf('(');
      final endIdx = marcaModeloStr.indexOf(')');
      storage = marcaModeloStr.substring(startIdx + 1, endIdx);
      model = marcaModeloStr.substring(0, startIdx).trim();
    }

    if (model.contains(' - ')) {
      final parts = model.split(' - ');
      model = parts[0].trim();
      color = parts[1].trim();
    }

    // Parser de acessórios serializados no problemaRelatado
    final problemaStr = _ultimaOrdemCliente!.problemaRelatado;
    bool hasChip = _parseAcessorio(problemaStr, 'Chip');
    bool hasPelicula = _parseAcessorio(problemaStr, 'Película');
    bool hasCapinha = _parseAcessorio(problemaStr, 'Capinha');

    setState(() {
      _marcaModeloController.text = model;
      _corController.text = color;
      _armazenamento = storage;
      _senhaController.text = _ultimaOrdemCliente!.senhaDesbloqueio;
      _displayOk = _ultimaOrdemCliente!.checkDisplay;
      _touchOk = _ultimaOrdemCliente!.checkTouch;
      _chipOk = hasChip;
      _peliculaOk = hasPelicula;
      _capinhaOk = hasCapinha;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados do último aparelho importados com sucesso!'),
        backgroundColor: Color(0xFF1565C0),
      ),
    );
  }

  bool _parseAcessorio(String text, String acessorio) {
    final regExp = RegExp(acessorio + r': (Sim|Não)');
    final match = regExp.firstMatch(text);
    if (match != null) {
      return match.group(1) == 'Sim';
    }
    return false;
  }

  // Abre o bottom sheet para selecionar ou cadastrar cliente
  void _abrirSelecaoCliente() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectorClienteSheet(
          db: _db,
          onClienteSelecionado: (cliente) {
            setState(() {
              _clienteSelecionado = cliente;
              _ultimaOrdemCliente = null; // limpa anterior para buscar nova
            });
            _verificarUltimoAparelho(cliente);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _salvarOS() async {
    if (_clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um cliente para vincular o serviço!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Concatena Modelo + Cor + Armazenamento para salvar no banco
      final modeloFormatado = _marcaModeloController.text.trim();
      final corFormatada = _corController.text.trim();
      final marcaModeloCompleto = corFormatada.isNotEmpty 
          ? '$modeloFormatado - $corFormatada ($_armazenamento)'
          : '$modeloFormatado ($_armazenamento)';
      
      // Serializa os acessórios de forma estruturada no campo de problema relatado
      final problemaTexto = _problemaController.text.trim();
      final problemaCompleto = '$problemaTexto\n\n[Acessórios: Chip: ${_chipOk ? 'Sim' : 'Não'}, Película: ${_peliculaOk ? 'Sim' : 'Não'}, Capinha: ${_capinhaOk ? 'Sim' : 'Não'}]';

      final novaOrdem = OrdensServicoCompanion(
        clienteId: drift.Value(_clienteSelecionado!.id),
        tipoRegistro: drift.Value(_tipoRegistro),
        dataEntrada: drift.Value(DateTime.now()),
        marcaModelo: drift.Value(marcaModeloCompleto),
        // Troca do IMEI por CPF do Cliente (salva o CPF na coluna imei do banco de dados)
        imei: drift.Value(_clienteSelecionado!.cpf),
        senhaDesbloqueio: drift.Value(_senhaController.text.trim()),
        checkDisplay: drift.Value(_displayOk),
        checkTouch: drift.Value(_touchOk),
        problemaRelatado: drift.Value(problemaCompleto),
        status: drift.Value(_tipoRegistro == 'OS' ? 'Em Manutenção' : 'Pendente'),
      );

      try {
        await _db.inserirOrdem(novaOrdem);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tipoRegistro == 'OS' ? 'Ordem de Serviço' : 'Orçamento'} salvo com sucesso!'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
        Navigator.pop(context, true); // Retorna com sinal de sucesso
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar no banco de dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _tipoRegistro == 'OS' ? 'Abertura de OS' : 'Criar Orçamento',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Tipo de Registro
                _buildTipoRegistroToggle(),
                const SizedBox(height: 16),

                // Seleção de Cliente
                _buildClienteSelectorSection(),
                
                // Banner Inteligente de Auto-preenchimento
                if (_ultimaOrdemCliente != null) ...[
                  const SizedBox(height: 12),
                  _buildAutoFillBanner(),
                ],
                
                const SizedBox(height: 16),

                // Ficha Técnica do Aparelho (Marca, Cor, Senha, CPF do Cliente)
                _buildTechnicalSpecsSection(),
                const SizedBox(height: 16),

                // Checklist de Entrada Físico e Acessórios
                _buildChecklistSection(),
                const SizedBox(height: 16),

                // Relato do Problema
                _buildProblemaSection(),
                const SizedBox(height: 24),

                // Botão de Salvar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _salvarOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _tipoRegistro == 'OS' ? 'Cadastrar Entrada de Serviço' : 'Registrar Orçamento',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipoRegistroToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tipoRegistro = 'OS'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tipoRegistro == 'OS' ? const Color(0xFF1565C0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Serviço Imediato (OS)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _tipoRegistro == 'OS' ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tipoRegistro = 'Orçamento'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _tipoRegistro == 'Orçamento' ? const Color(0xFF00897B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Orçamento (OC)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _tipoRegistro == 'Orçamento' ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteSelectorSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Identificação do Cliente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _abrirSelecaoCliente,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _clienteSelecionado == null
                          ? Text(
                              'Selecionar Cliente...',
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _clienteSelecionado!.nome,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'CPF: ${_clienteSelecionado!.cpf} • Tel: ${_clienteSelecionado!.telefone}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                )
                              ],
                            ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0), size: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoFillBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.history, color: Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aparelho Anterior Registrado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _ultimaOrdemCliente!.marcaModelo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _preencherComUltimoAparelho,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Puxar Dados', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecsSection() {
    final armOptions = ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB', 'N/A'];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_cell, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Ficha Técnica do Aparelho',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Marca/Modelo e Cor na mesma linha
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _marcaModeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo (ex: iPhone 13)',
                      prefixIcon: Icon(Icons.phone_iphone),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'O modelo é obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _corController,
                    decoration: const InputDecoration(
                      labelText: 'Cor (ex: Azul, Preto)',
                      prefixIcon: Icon(Icons.palette_outlined),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Cor é obrigatória' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Row para Armazenamento e Senha
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _armazenamento,
                    decoration: const InputDecoration(
                      labelText: 'Armazenamento',
                      prefixIcon: Icon(Icons.storage),
                    ),
                    items: armOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _armazenamento = val;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _senhaController,
                    decoration: InputDecoration(
                      labelText: 'Senha Desbloqueio',
                      prefixIcon: const Icon(Icons.password),
                      hintText: 'Senha ou padrão',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.gesture, color: Color(0xFF1565C0)),
                        onPressed: () async {
                          final String? pattern = await showDialog<String>(
                            context: context,
                            builder: (context) => const PatternLockDialog(),
                          );
                          if (pattern != null) {
                            setState(() {
                              _senhaController.text = pattern;
                            });
                          }
                        },
                        tooltip: 'Desenhar padrão',
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Recomendável registrar a senha' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // CPF do Cliente (Substituindo o IMEI antigo da OS)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.badge, color: Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identificação do Serviço (CPF do Cliente)',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _clienteSelecionado != null ? _clienteSelecionado!.cpf : 'Selecione um cliente para carregar o CPF',
                          style: TextStyle(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold,
                            color: _clienteSelecionado != null ? const Color(0xFF2C3E50) : Colors.grey[400],
                            fontStyle: _clienteSelecionado != null ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_clienteSelecionado != null)
                    const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.checklist, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Checklist Física e Acessórios',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Indique o estado físico das peças e acessórios deixados',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 14),
            
            // Título Peças
            Text('ESTADO DO APARELHO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
            const SizedBox(height: 8),
            
            // Switch Display
            _buildChecklistItem(
              'Display (Imagem)',
              'Imagem está nítida e sem listras',
              _displayOk,
              (v) => setState(() => _displayOk = v),
            ),
            const Divider(height: 18),
            
            // Switch Touch
            _buildChecklistItem(
              'Touch (Toque)',
              'Tela sensível ao toque responde perfeitamente',
              _touchOk,
              (v) => setState(() => _touchOk = v),
            ),
            
            const Divider(height: 24, thickness: 1.2),
            
            // Título Acessórios
            Text('ACESSÓRIOS DEIXADOS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.5)),
            const SizedBox(height: 10),

            // Switch Chip
            _buildChecklistItem(
              'Deixou com Chip?',
              'O cartão SIM foi mantido no aparelho',
              _chipOk,
              (v) => setState(() => _chipOk = v),
              isAccessory: true,
            ),
            const Divider(height: 18),

            // Switch Película
            _buildChecklistItem(
              'Deixou com Película?',
              'O smartphone possui película protetora',
              _peliculaOk,
              (v) => setState(() => _peliculaOk = v),
              isAccessory: true,
            ),
            const Divider(height: 18),

            // Switch Capinha
            _buildChecklistItem(
              'Deixou com Capinha?',
              'A capa de proteção foi recebida',
              _capinhaOk,
              (v) => setState(() => _capinhaOk = v),
              isAccessory: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, String desc, bool value, ValueChanged<bool> onChanged, {bool isAccessory = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              isAccessory 
                ? (value ? 'SIM' : 'NÃO')
                : (value ? 'OK' : 'DANIFICADO'),
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: value 
                    ? (isAccessory ? const Color(0xFF1565C0) : const Color(0xFF27AE60)) 
                    : (isAccessory ? Colors.grey[600] : Colors.redAccent),
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: isAccessory ? const Color(0xFF1565C0) : const Color(0xFF27AE60),
              activeTrackColor: isAccessory ? const Color(0xFF1565C0).withValues(alpha: 0.2) : const Color(0xFF27AE60).withValues(alpha: 0.2),
              inactiveThumbColor: isAccessory ? Colors.grey[400] : Colors.redAccent,
              inactiveTrackColor: isAccessory ? Colors.grey[300] : Colors.redAccent.withValues(alpha: 0.2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProblemaSection() {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem_outlined, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Relato do Problema / Defeito',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _problemaController,
              decoration: const InputDecoration(
                hintText: 'Descreva os problemas observados ou relatados pelo cliente (Ex: Celular caiu na água, tela trincada, não carrega)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (v) => v == null || v.isEmpty ? 'Relatar o problema é essencial para a manutenção' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Bottom Sheet customizada para busca e cadastro rápido de clientes
class _SelectorClienteSheet extends StatefulWidget {
  final AppDatabase db;
  final ValueChanged<Cliente> onClienteSelecionado;

  const _SelectorClienteSheet({required this.db, required this.onClienteSelecionado});

  @override
  State<_SelectorClienteSheet> createState() => _SelectorClienteSheetState();
}

class _SelectorClienteSheetState extends State<_SelectorClienteSheet> {
  final _searchController = TextEditingController();
  List<Cliente> _clientes = [];
  List<Cliente> _filtrados = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _buscarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buscarClientes() async {
    setState(() => _carregando = true);
    try {
      final list = await widget.db.listarClientes();
      setState(() {
        _clientes = list;
        _filtrar( _searchController.text );
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _filtrar(String query) {
    if (query.isEmpty) {
      setState(() {
        _filtrados = List.from(_clientes);
      });
    } else {
      final lower = query.toLowerCase();
      setState(() {
        _filtrados = _clientes.where((c) {
          return c.nome.toLowerCase().contains(lower) || 
                 c.cpf.toLowerCase().contains(lower) || 
                 c.telefone.toLowerCase().contains(lower);
        }).toList();
      });
    }
  }

  // Formulário rápido para cadastro de cliente dentro do bottom sheet
  void _mostrarCadastroRapidoCliente() {
    final nomeController = TextEditingController();
    final cpfController = TextEditingController();
    final telefoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cadastro Rápido'),
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
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: telefoneController,
                    decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Telefone é obrigatório' : null,
                  ),
                  const SizedBox(height: 10),
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
                  final novo = ClientesCompanion(
                    nome: drift.Value(nomeController.text.trim()),
                    telefone: drift.Value(telefoneController.text.trim()),
                    cpf: drift.Value(cpfController.text.trim()),
                  );
                  try {
                    final id = await widget.db.inserirCliente(novo);
                    if (!context.mounted) return;
                    final recemCriado = Cliente(
                      id: id,
                      nome: nomeController.text.trim(),
                      telefone: telefoneController.text.trim(),
                      cpf: cpfController.text.trim(),
                    );
                    Navigator.pop(context); // fecha dialog
                    widget.onClienteSelecionado(recemCriado); // retorna e pré-seleciona!
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao salvar cliente: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              child: const Text('Salvar e Selecionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Barra de arrasto superior
          const SizedBox(height: 12),
          Container(
            width: 45,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 14),
          
          // Título e Botão Adicionar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vincular Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                TextButton.icon(
                  onPressed: _mostrarCadastroRapidoCliente,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Criar Novo', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1565C0)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Barra de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filtrar,
                decoration: const InputDecoration(
                  hintText: 'Procurar por nome ou CPF...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF1565C0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Lista de resultados
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('Nenhum cliente cadastrado.', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        itemCount: _filtrados.length,
                        itemBuilder: (context, index) {
                          final c = _filtrados[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.08),
                                child: const Icon(Icons.person, color: Color(0xFF1565C0)),
                              ),
                              title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Tel: ${c.telefone} • CPF: ${c.cpf}', style: const TextStyle(fontSize: 12)),
                              onTap: () => widget.onClienteSelecionado(c),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class PatternLockDialog extends StatefulWidget {
  const PatternLockDialog({super.key});

  @override
  State<PatternLockDialog> createState() => _PatternLockDialogState();
}

class _PatternLockDialogState extends State<PatternLockDialog> {
  final List<int> _selectedPoints = [];
  Offset? _currentTouchPosition;

  Offset _getOffset(int index, Size size) {
    double stepX = size.width / 4;
    double stepY = size.height / 4;
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(stepX * (col + 1), stepY * (row + 1));
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final Offset localPos = details.localPosition;
    setState(() {
      _currentTouchPosition = localPos;
    });

    for (int i = 0; i < 9; i++) {
      final Offset pointPos = _getOffset(i, size);
      final double distance = (localPos - pointPos).distance;
      if (distance < 24.0) { // Raio de tolerância de 24 pixels
        if (!_selectedPoints.contains(i)) {
          setState(() {
            _selectedPoints.add(i);
          });
        }
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _currentTouchPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.gesture, color: Color(0xFF1565C0)),
          SizedBox(width: 8),
          Text('Desenhar Padrão'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Arraste o dedo conectando os pontos para definir a senha do celular do cliente.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, const Size(240, 240)),
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _PatternCapturePainter(
                  points: _selectedPoints,
                  currentPos: _currentTouchPosition,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPoints.clear();
                    _currentTouchPosition = null;
                  });
                },
                child: const Text('Limpar', style: TextStyle(color: Colors.redAccent)),
              ),
              Text(
                'Seq: ${_selectedPoints.join(' → ')}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _selectedPoints.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedPoints.join(',')),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _PatternCapturePainter extends CustomPainter {
  final List<int> points;
  final Offset? currentPos;

  _PatternCapturePainter({required this.points, required this.currentPos});

  Offset _getOffset(int index, Size size) {
    double stepX = size.width / 4;
    double stepY = size.height / 4;
    int row = index ~/ 3;
    int col = index % 3;
    return Offset(stepX * (col + 1), stepY * (row + 1));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Desenha conexões
    final linePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    if (points.length > 1) {
      Path path = Path();
      Offset start = _getOffset(points.first, size);
      path.moveTo(start.dx, start.dy);

      for (int i = 1; i < points.length; i++) {
        Offset next = _getOffset(points[i], size);
        path.lineTo(next.dx, next.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Linha temporária
    if (points.isNotEmpty && currentPos != null) {
      Offset lastPoint = _getOffset(points.last, size);
      canvas.drawLine(lastPoint, currentPos!, linePaint..color = const Color(0xFF1565C0).withValues(alpha: 0.5));
    }

    // 2. Desenha nós
    final dotPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    final activeDotPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 9; i++) {
      Offset pos = _getOffset(i, size);
      bool isActive = points.contains(i);
      
      canvas.drawCircle(pos, isActive ? 8.0 : 6.0, isActive ? activeDotPaint : dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternCapturePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.currentPos != currentPos;
  }
}
