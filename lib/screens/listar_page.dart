
import 'package:flutter/material.dart';
// IMPORTAÇÃO ATUALIZADA PARA O SEU BANCO:
import '../database/aoo_database.dart'; 

class ListarPage extends StatefulWidget {
  @override
  _ListarPageState createState() => _ListarPageState();
}

class _ListarPageState extends State<ListarPage> {
  late AppDatabase _db;
  late Future<List<Cliente>> _clientesFuture;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase(); // Conecta ao banco
    _atualizarLista(); // Busca os clientes ao abrir a tela
  }

  void _atualizarLista() {
    setState(() {
      _clientesFuture = _db.listarClientes();
    });
  }

  @override
  void dispose() {
    _db.close(); 
    super.dispose();
  }

  // Função para apagar um cliente
  void _excluirCliente(int id) async {
    await _db.excluirCliente(id);
    _atualizarLista(); 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente excluído com sucesso!')),
    );
  }

  // Função para abrir uma janelinha e editar o cliente
  void _mostrarDialogoEditar(Cliente cliente) {
    final nomeController = TextEditingController(text: cliente.nome);
    final cpfController = TextEditingController(text: cliente.cpf);
    final telefoneController = TextEditingController(text: cliente.telefone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: cpfController, decoration: const InputDecoration(labelText: 'CPF')),
              TextField(controller: telefoneController, decoration: const InputDecoration(labelText: 'Telefone')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final clienteAtualizado = Cliente(
                  id: cliente.id,
                  nome: nomeController.text,
                  cpf: cpfController.text,
                  telefone: telefoneController.text,
                );
                await _db.atualizarCliente(clienteAtualizado);
                Navigator.pop(context);
                _atualizarLista(); 
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Clientes')),
      body: FutureBuilder<List<Cliente>>(
        future: _clientesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); 
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum cliente cadastrado.'));
          }

          final clientes = snapshot.data!;

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente.nome),
                subtitle: Text('CPF: ${cliente.cpf} - Tel: ${cliente.telefone}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialogoEditar(cliente), 
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _excluirCliente(cliente.id), 
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}