import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class DetalhesOsPage extends StatefulWidget {
  const DetalhesOsPage({super.key});

  @override
  State<DetalhesOsPage> createState() => _DetalhesOsPageState();
}

class _DetalhesOsPageState extends State<DetalhesOsPage> {
  final AppDatabase _db = AppDatabase();
  
  OrdemComCliente? _item;
  bool _carregando = false;
  
  // Controladores para Finalização
  final _servicoController = TextEditingController();
  final _valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Controladores para Proposta de Orçamento
  final _propServicoController = TextEditingController();
  final _propValorController = TextEditingController();
  final _propFormKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_item == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is OrdemComCliente) {
        _item = args;
        _servicoController.text = args.ordem.servicoExecutado ?? '';
        _valorController.text = args.ordem.valor != null ? args.ordem.valor!.toStringAsFixed(2) : '';
        _propServicoController.text = args.ordem.servicoExecutado ?? '';
        _propValorController.text = args.ordem.valor != null ? args.ordem.valor!.toStringAsFixed(2) : '';
      }
    }
  }

  @override
  void dispose() {
    _servicoController.dispose();
    _valorController.dispose();
    _propServicoController.dispose();
    _propValorController.dispose();
    super.dispose();
  }

  Future<void> _recarregarDados() async {
    if (_item == null) return;
    setState(() => _carregando = true);
    
    try {
      // Busca ordens atualizadas
      final ordens = await _db.listarOrdensComCliente();
      final atualizado = ordens.firstWhere((element) => element.ordem.id == _item!.ordem.id);
      
      setState(() {
        _item = atualizado;
        _servicoController.text = atualizado.ordem.servicoExecutado ?? '';
        _valorController.text = atualizado.ordem.valor != null ? atualizado.ordem.valor!.toStringAsFixed(2) : '';
        _propServicoController.text = atualizado.ordem.servicoExecutado ?? '';
        _propValorController.text = atualizado.ordem.valor != null ? atualizado.ordem.valor!.toStringAsFixed(2) : '';
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      _mostrarSnackBar('Erro ao atualizar dados: $e');
    }
  }

  // Atualiza apenas o status no banco de forma cirúrgica
  Future<void> _atualizarStatus(String novoStatus) async {
    if (_item == null) return;
    
    try {
      await (_db.update(_db.ordensServico)..where((t) => t.id.equals(_item!.ordem.id)))
          .write(OrdensServicoCompanion(
            status: drift.Value(novoStatus),
          ));
      
      if (!mounted) return;
      _mostrarSnackBar('Status alterado para $novoStatus');
      _recarregarDados();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Erro ao alterar status: $e');
    }
  }

  void _handleAprovar() {
    if (_propFormKey.currentState!.validate()) {
      final valor = double.tryParse(_propValorController.text.replaceAll(',', '.')) ?? 0.0;
      _aprovarOrcamento(_propServicoController.text.trim(), valor);
    }
  }

  void _handleRecusar() {
    if (_propServicoController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor, informe o diagnóstico no campo de serviço para recusar.');
      return;
    }
    _recusarOrcamento(_propServicoController.text.trim());
  }

  // Salva o serviço executado e valor final e disponibiliza para retirada
  Future<void> _finalizarServico() async {
    if (_item == null) return;
    
    if (_formKey.currentState!.validate()) {
      final valorDigitado = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;
      
      try {
        await (_db.update(_db.ordensServico)..where((t) => t.id.equals(_item!.ordem.id)))
            .write(OrdensServicoCompanion(
              status: const drift.Value('Aguardando Retirada'),
              servicoExecutado: drift.Value(_servicoController.text.trim()),
              valor: drift.Value(valorDigitado),
            ));
        
        if (!mounted) return;
        _mostrarSnackBar('Serviço concluído! Disponibilizado para retirada.');
        _recarregarDados();
      } catch (e) {
        if (!mounted) return;
        _mostrarSnackBar('Erro ao finalizar serviço: $e');
      }
    }
  }

  // Aprova o orçamento e inicia manutenção
  Future<void> _aprovarOrcamento(String diagnostico, double valor) async {
    if (_item == null) return;
    try {
      await (_db.update(_db.ordensServico)..where((t) => t.id.equals(_item!.ordem.id)))
          .write(OrdensServicoCompanion(
            status: const drift.Value('Em Manutenção'),
            servicoExecutado: drift.Value('Orçamento Aprovado: $diagnostico'),
            valor: drift.Value(valor),
          ));
      if (!mounted) return;
      _mostrarSnackBar('Orçamento aprovado! Aparelho em Manutenção.');
      _recarregarDados();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Erro ao aprovar orçamento: $e');
    }
  }

  // Recusa o orçamento e disponibiliza para retirada
  Future<void> _recusarOrcamento(String diagnostico) async {
    if (_item == null) return;
    try {
      await (_db.update(_db.ordensServico)..where((t) => t.id.equals(_item!.ordem.id)))
          .write(OrdensServicoCompanion(
            status: const drift.Value('Aguardando Retirada'),
            servicoExecutado: drift.Value('Orçamento Recusado: $diagnostico'),
            valor: const drift.Value(0.0),
          ));
      if (!mounted) return;
      _mostrarSnackBar('Orçamento recusado! Aparelho disponível para retirada.');
      _recarregarDados();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Erro ao recusar orçamento: $e');
    }
  }

  // Confirma entrega física do aparelho e conclui a OS
  Future<void> _confirmarEntrega() async {
    if (_item == null) return;
    try {
      await (_db.update(_db.ordensServico)..where((t) => t.id.equals(_item!.ordem.id)))
          .write(OrdensServicoCompanion(
            status: const drift.Value('Concluído'),
          ));
      if (!mounted) return;
      _mostrarSnackBar('Aparelho entregue! Serviço concluído.');
      _recarregarDados();
    } catch (e) {
      if (!mounted) return;
      _mostrarSnackBar('Erro ao registrar entrega: $e');
    }
  }

  // Confirma exclusão da OS
  void _confirmarExclusao() async {
    if (_item == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Ordem'),
        content: Text('Deseja realmente apagar permanentemente a Ordem #${_item!.ordem.id} do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _db.excluirOrdem(_item!.ordem.id);
        if (!mounted) return;
        _mostrarSnackBar('Ordem de serviço excluída com sucesso!');
        Navigator.pop(context, true); // Retorna sinalizando que foi excluído
      } catch (e) {
        if (!mounted) return;
        _mostrarSnackBar('Erro ao excluir: $e');
      }
    }
  }

  void _mostrarSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // Ações de Contato Simulado
  void _simularLigacao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: Colors.blue),
            SizedBox(width: 10),
            Text('Simulando Ligação'),
          ],
        ),
        content: Text('Iniciando chamada para ${_item!.cliente.nome} no número ${_item!.cliente.telefone}...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _simularWhatsApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
            SizedBox(width: 10),
            Text('Contato WhatsApp'),
          ],
        ),
        content: Text('Abrindo conversa com ${_item!.cliente.nome} (${_item!.cliente.telefone})\n\nMensagem padrão: "Olá, sou da assistência Telecell. Sua ordem de serviço do aparelho ${_item!.ordem.marcaModelo} foi atualizada para: ${_item!.ordem.status}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
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

  String _limparProblemaTexto(String text) {
    final idx = text.indexOf('\n\n[Acessórios:');
    if (idx != -1) {
      return text.substring(0, idx).trim();
    }
    return text;
  }

  Widget _buildAccessoryBadge(String label, bool hasIt) {
    final activeColor = const Color(0xFF1565C0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: hasIt ? activeColor.withValues(alpha: 0.1) : Colors.grey[200]!.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasIt ? activeColor.withValues(alpha: 0.3) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasIt ? Icons.check_box : Icons.check_box_outline_blank,
              size: 15,
              color: hasIt ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: hasIt ? activeColor : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma ordem de serviço foi carregada.')),
      );
    }

    final isOrcamento = _item!.ordem.tipoRegistro.toLowerCase().contains('orç') || 
                        _item!.ordem.tipoRegistro.toLowerCase().contains('orc');

    Color statusColor;
    switch (_item!.ordem.status.toLowerCase()) {
      case 'pendente':
      case 'aberta':
        statusColor = const Color(0xFFE67E22);
        break;
      case 'em manutenção':
      case 'em manutencao':
        statusColor = const Color(0xFF2980B9);
        break;
      case 'aguardando retirada':
      case 'aguardo de retirada':
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${isOrcamento ? 'OC' : 'OS'} #${_item!.ordem.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: _confirmarExclusao,
            tooltip: 'Excluir serviço',
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Visual de Status
                  _buildStepperVisual(),
                  const SizedBox(height: 18),

                  // Dados do Cliente
                  _buildClienteInfoCard(),
                  const SizedBox(height: 16),

                  // Ficha Técnica e Checklist
                  _buildTechnicalInfoCard(),
                  const SizedBox(height: 16),

                  // Gestão de Status (Ações do Técnico)
                  if (_item!.ordem.status != 'Concluído') _buildStatusActionsCard(statusColor),
                  const SizedBox(height: 16),

                  // Área de Finalização (Reparo e Valor)
                  _buildFinalizationCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStepperVisual() {
    final statusList = ['Pendente', 'Em Manutenção', 'Aguardando Retirada', 'Concluído'];
    final currentStatus = _item!.ordem.status;
    int currentIndex = statusList.indexOf(currentStatus);
    
    // Se por acaso o status for 'Aberta', mapeamos para Pendente
    if (currentStatus == 'Aberta') currentIndex = 0;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(statusList.length, (index) {
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;
                Color bulletColor = isCompleted ? const Color(0xFF1565C0) : Colors.grey[300]!;
                if (isCurrent) {
                  bulletColor = const Color(0xFFE67E22); // Destaque para o status atual
                }

                return Row(
                  children: [
                    // Círculo
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: bulletColor,
                          child: Icon(
                            index < currentIndex ? Icons.check : (isCurrent ? Icons.play_arrow : Icons.radio_button_unchecked),
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statusList[index],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? const Color(0xFFE67E22) : (isCompleted ? const Color(0xFF1565C0) : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteInfoCard() {
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
                  'Ficha do Cliente',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item!.cliente.nome,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 4),
                      Text('CPF: ${_item!.cliente.cpf}', style: const TextStyle(fontSize: 12)),
                      Text('Telefone: ${_item!.cliente.telefone}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Botões de contato dinâmico
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFF1565C0)),
                      onPressed: _simularLigacao,
                      tooltip: 'Ligar para cliente',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      onPressed: _simularWhatsApp,
                      tooltip: 'WhatsApp',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalInfoCard() {
    final problemaStr = _item!.ordem.problemaRelatado;
    final hasChip = _parseAcessorio(problemaStr, 'Chip');
    final hasPelicula = _parseAcessorio(problemaStr, 'Película');
    final hasCapinha = _parseAcessorio(problemaStr, 'Capinha');

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_cell, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text(
                      'Ficha Técnica do Celular',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _item!.ordem.tipoRegistro.toLowerCase().contains('orç')
                        ? const Color(0xFF00897B).withValues(alpha: 0.12)
                        : const Color(0xFF1565C0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _item!.ordem.tipoRegistro,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _item!.ordem.tipoRegistro.toLowerCase().contains('orç')
                          ? const Color(0xFF00897B)
                          : const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            
            // Marca/Modelo e Data
            _buildDetailRow('Aparelho:', _item!.ordem.marcaModelo, isHighlight: true),
            const SizedBox(height: 8),
            _buildDetailRow('CPF do Cliente:', _item!.ordem.imei),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Senha de Desbloqueio:', 
              _item!.ordem.senhaDesbloqueio.isNotEmpty ? _item!.ordem.senhaDesbloqueio : 'Não informada',
              isPass: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Data de Entrada:',
              '${_item!.ordem.dataEntrada.day.toString().padLeft(2, '0')}/${_item!.ordem.dataEntrada.month.toString().padLeft(2, '0')}/${_item!.ordem.dataEntrada.year} às ${_item!.ordem.dataEntrada.hour.toString().padLeft(2, '0')}:${_item!.ordem.dataEntrada.minute.toString().padLeft(2, '0')}',
            ),
            const Divider(height: 24),
            
            // Checklist Físico
            const Text(
              'Estado do Aparelho:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCheckBadge('Display', _item!.ordem.checkDisplay),
                const SizedBox(width: 12),
                _buildCheckBadge('Touchscreen', _item!.ordem.checkTouch),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Acessórios Deixados:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildAccessoryBadge('Chip', hasChip),
                const SizedBox(width: 8),
                _buildAccessoryBadge('Película', hasPelicula),
                const SizedBox(width: 8),
                _buildAccessoryBadge('Capinha', hasCapinha),
              ],
            ),
            const Divider(height: 24),

            // Defeito relatado
            const Text(
              'Defeito / Problema Relatado:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              ),
              child: Text(
                _limparProblemaTexto(_item!.ordem.problemaRelatado),
                style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false, bool isPass = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: isPass ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3) : null,
            decoration: isPass
                ? BoxDecoration(
                    color: const Color(0xFFFFF9C4), // Destaque amarelado para senha
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.5)),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isHighlight || isPass) ? FontWeight.bold : FontWeight.normal,
                color: isPass ? const Color(0xFFF57F17) : const Color(0xFF2C3E50),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckBadge(String label, bool isOk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isOk ? const Color(0xFF27AE60).withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isOk ? const Color(0xFF27AE60).withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOk ? Icons.check_circle_outline : Icons.error_outline,
              size: 16,
              color: isOk ? const Color(0xFF27AE60) : Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$label: ${isOk ? 'OK' : 'DEFEITO'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isOk ? const Color(0xFF27AE60) : Colors.redAccent,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActionsCard(Color statusColor) {
    final statusList = ['Pendente', 'Em Manutenção', 'Aguardando Retirada'];
    final current = _item!.ordem.status == 'Aberta' ? 'Pendente' : _item!.ordem.status;

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
                Icon(Icons.cached, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Text(
                  'Atualizar Status do Serviço',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: statusList.map((st) {
                  final isSelected = current == st;
                  Color activeColor;
                  switch (st) {
                    case 'Pendente':
                      activeColor = const Color(0xFFE67E22);
                      break;
                    case 'Em Manutenção':
                      activeColor = const Color(0xFF2980B9);
                      break;
                    case 'Aguardando Retirada':
                      activeColor = const Color(0xFF8E44AD);
                      break;
                    default:
                      activeColor = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        st,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _atualizarStatus(st);
                        }
                      },
                      selectedColor: activeColor,
                      backgroundColor: const Color(0xFFF1F3F5),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizationCard() {
    final status = _item!.ordem.status;

    if (status == 'Concluído') {
      return Card(
        color: const Color(0xFFE8F5E9), // Fundo verde leve
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF81C784), width: 1),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text(
                    'Serviço Concluído e Entregue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFF81C784)),
              _buildDetailRow(
                'Serviço Realizado:',
                _item!.ordem.servicoExecutado ?? 'Nenhum serviço registrado',
                isHighlight: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Valor Cobrado:',
                'R\$ ${_item!.ordem.valor != null ? _item!.ordem.valor!.toStringAsFixed(2) : '0,00'}',
                isHighlight: true,
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'Aguardando Retirada') {
      return Card(
        color: const Color(0xFFF3E5F5), // Fundo roxo leve premium
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFB39DDB), width: 1),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.mark_as_unread, color: Color(0xFF7B1FA2)),
                  SizedBox(width: 8),
                  Text(
                    'Aparelho Aguardando Retirada',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
                  ),
                ],
              ),
              const Divider(height: 20, color: Color(0xFFB39DDB)),
              _buildDetailRow(
                'Serviço/Diagnóstico:',
                _item!.ordem.servicoExecutado ?? 'Não detalhado',
                isHighlight: true,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Valor a ser Pago:',
                'R\$ ${_item!.ordem.valor != null ? _item!.ordem.valor!.toStringAsFixed(2) : '0,00'}',
                isHighlight: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _confirmarEntrega,
                  icon: const Icon(Icons.delivery_dining, size: 22),
                  label: const Text(
                    'Confirmar Entrega e Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'Pendente') {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFCC80), width: 1), // Borda laranja leve
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _propFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: Color(0xFFE67E22)),
                    SizedBox(width: 8),
                    Text(
                      'Avaliação e Proposta de Orçamento',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Diagnóstico / Serviço Proposto
                TextFormField(
                  controller: _propServicoController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico Técnico / Serviço Proposto',
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Ex: Troca de tela frontal e conector de carga...',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o diagnóstico/serviço proposto' : null,
                ),
                const SizedBox(height: 14),

                // Valor Proposto
                TextFormField(
                  controller: _propValorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor do Orçamento (R\$)',
                    prefixIcon: Icon(Icons.sell),
                    hintText: '0,00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe o valor proposto';
                    final parse = double.tryParse(v.replaceAll(',', '.'));
                    if (parse == null || parse < 0) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleRecusar,
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text(
                          'Recusar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleAprovar,
                        icon: const Icon(Icons.play_circle_outline, size: 20),
                        label: const Text(
                          'Aprovar e Iniciar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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

    // Default or Em Manutenção
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.build_circle_outlined, color: Color(0xFF2980B9)),
                  SizedBox(width: 8),
                  Text(
                    'Finalização e Faturamento de Conserto',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Serviço Executado
              TextFormField(
                controller: _servicoController,
                decoration: const InputDecoration(
                  labelText: 'Serviço Executado / Reparo Realizado',
                  prefixIcon: Icon(Icons.build_circle),
                  hintText: 'Descreva a solução efetuada...',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Informe o serviço executado para finalizar' : null,
              ),
              const SizedBox(height: 14),

              // Valor Cobrado
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor Final Cobrado (R\$)',
                  prefixIcon: Icon(Icons.payments),
                  hintText: '0,00',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o valor cobrado';
                  final parse = double.tryParse(v.replaceAll(',', '.'));
                  if (parse == null || parse < 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botão Finalizar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _finalizarServico,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text(
                    'Concluir Reparo (Disponibilizar para Retirada)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2980B9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
