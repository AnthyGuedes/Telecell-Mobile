import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';


part 'aoo_database.g.dart';

// Definição da tabela de clientes
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()(); // Chave primária
  TextColumn get nome => text()(); // Nome obrigatório
  TextColumn get cpf => text()(); // CPF obrigatório
  TextColumn get telefone => text()(); // Telefone obrigatório
}

// Classe principal do banco
@DriftDatabase(tables: [Clientes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexao());

  @override
  int get schemaVersion => 1;

  // CRUD: inserir cliente
  Future<int> inserirCliente(ClientesCompanion cliente) =>
      into(clientes).insert(cliente);

  // Listar todos os clientes
  Future<List<Cliente>> listarClientes() => select(clientes).get();

  // Atualizar cliente existente
  Future<bool> atualizarCliente(Cliente cliente) =>
      update(clientes).replace(cliente);

  // Excluir cliente por ID
  Future<int> excluirCliente(int id) =>
      (delete(clientes)..where((t) => t.id.equals(id))).go();
}

// Função que cria e retorna a conexão com o arquivo do banco no celular
LazyDatabase _abrirConexao() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory(); 
    final path = p.join(dir.path, 'clientes.db'); 
    return NativeDatabase(File(path)); 
  });
}