import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart'; // Importa o seu banco

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // Instância do banco de dados
  late AooDatabase _db;

  // Controladores para capturar o texto digitado
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _db = AooDatabase(); // Inicia o banco de dados
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _db.close(); // Fecha o banco ao sair da tela
    super.dispose();
  }

  // Função para salvar no banco usando o Drift
  void _salvarCliente() async {
    if (_nomeController.text.isNotEmpty && _cpfController.text.isNotEmpty && _telefoneController.text.isNotEmpty) {
      
      // Usa o ClientesCompanion (gerado pelo build_runner) para inserir os dados
      final novoCliente = ClientesCompanion(
        nome: drift.Value(_nomeController.text),
        cpf: drift.Value(_cpfController.text),
        telefone: drift.Value(_telefoneController.text),
      );

      await _db.inserirCliente(novoCliente);

      // Limpa os campos após salvar
      _nomeController.clear();
      _cpfController.clear();
      _telefoneController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _cpfController,
              decoration: const InputDecoration(labelText: 'CPF'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarCliente,
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                // Navega para a tela de listagem
                Navigator.pushNamed(context, '/listar');
              },
              child: const Text('Ver lista de clientes'),
            )
          ],
        ),
      ),
    );
  }
}