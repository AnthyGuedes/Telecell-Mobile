import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

// =============================================================================
// TABELA: Clientes
// =============================================================================
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nome => text()();
  TextColumn get telefone => text()();
  TextColumn get cpf => text()();
}

// =============================================================================
// TABELA: OrdensServico
// =============================================================================
@DataClassName('OrdemDeServico')
class OrdensServico extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Chave estrangeira -> Clientes.id
  IntColumn get clienteId =>
      integer().references(Clientes, #id)();

  TextColumn get tipoRegistro => text()();
  DateTimeColumn get dataEntrada => dateTime()();
  TextColumn get marcaModelo => text()();
  TextColumn get imei => text()();
  TextColumn get senhaDesbloqueio => text()();
  BoolColumn get checkDisplay => boolean().withDefault(const Constant(false))();
  BoolColumn get checkTouch => boolean().withDefault(const Constant(false))();
  TextColumn get problemaRelatado => text()();
  TextColumn get servicoExecutado => text().nullable()();
  RealColumn get valor => real().nullable()();
  TextColumn get status => text().withDefault(const Constant('Aberta'))();
}

// =============================================================================
// CLASSE DO BANCO DE DADOS
// =============================================================================
@DriftDatabase(tables: [Clientes, OrdensServico])
class AppDatabase extends _$AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  AppDatabase._internal() : super(_abrirConexao());

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------------------------------
  // CLIENTES — CRUD
  // ---------------------------------------------------------------------------

  /// Insere um novo cliente e retorna o ID gerado.
  Future<int> inserirCliente(ClientesCompanion cliente) =>
      into(clientes).insert(cliente);

  /// Retorna todos os clientes ordenados por nome.
  Future<List<Cliente>> listarClientes() =>
      (select(clientes)..orderBy([(t) => OrderingTerm.asc(t.nome)])).get();

  /// Busca clientes pelo nome (busca parcial, case-insensitive).
  Future<List<Cliente>> buscarClientesPorNome(String nome) =>
      (select(clientes)
            ..where((t) => t.nome.lower().like('%${nome.toLowerCase()}%')))
          .get();

  /// Atualiza os dados de um cliente existente.
  Future<bool> atualizarCliente(Cliente cliente) =>
      update(clientes).replace(cliente);

  /// Exclui um cliente por ID.
  Future<int> excluirCliente(int id) =>
      (delete(clientes)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // ORDENS DE SERVIÇO — CRUD
  // ---------------------------------------------------------------------------

  /// Insere uma nova OS e retorna o ID gerado.
  Future<int> inserirOrdem(OrdensServicoCompanion ordem) =>
      into(ordensServico).insert(ordem);

  /// Atualiza uma OS existente.
  Future<bool> atualizarOrdem(OrdensServicoCompanion ordem) =>
      update(ordensServico).replace(ordem);

  /// Exclui uma OS por ID.
  Future<int> excluirOrdem(int id) =>
      (delete(ordensServico)..where((t) => t.id.equals(id))).go();

  // ---------------------------------------------------------------------------
  // ORDENS DE SERVIÇO — QUERIES COM JOIN
  // ---------------------------------------------------------------------------

  /// Retorna todas as OS com os dados do cliente (JOIN Clientes).
  Future<List<OrdemComCliente>> listarOrdensComCliente() async {
    final query = select(ordensServico).join([
      innerJoin(clientes, clientes.id.equalsExp(ordensServico.clienteId)),
    ])
      ..orderBy([OrderingTerm.desc(ordensServico.dataEntrada)]);

    final rows = await query.get();
    return rows
        .map((row) => OrdemComCliente(
              ordem: row.readTable(ordensServico),
              cliente: row.readTable(clientes),
            ))
        .toList();
  }

  /// Busca OS por nome do cliente ou por status.
  Future<List<OrdemComCliente>> buscarOrdens({
    String? nomeCliente,
    String? status,
  }) async {
    final query = select(ordensServico).join([
      innerJoin(clientes, clientes.id.equalsExp(ordensServico.clienteId)),
    ]);

    if (nomeCliente != null && nomeCliente.isNotEmpty) {
      query.where(
          clientes.nome.lower().like('%${nomeCliente.toLowerCase()}%'));
    }
    if (status != null && status.isNotEmpty) {
      query.where(ordensServico.status.equals(status));
    }

    query.orderBy([OrderingTerm.desc(ordensServico.dataEntrada)]);

    final rows = await query.get();
    return rows
        .map((row) => OrdemComCliente(
              ordem: row.readTable(ordensServico),
              cliente: row.readTable(clientes),
            ))
        .toList();
  }

  /// Retorna todas as OS de um cliente específico.
  Future<List<OrdemDeServico>> listarOrdensPorCliente(int clienteId) =>
      (select(ordensServico)
            ..where((t) => t.clienteId.equals(clienteId))
            ..orderBy([(t) => OrderingTerm.desc(t.dataEntrada)]))
          .get();
}

// =============================================================================
// DATA CLASS AUXILIAR — Ordem + Cliente (resultado do JOIN)
// =============================================================================
class OrdemComCliente {
  final OrdemDeServico ordem;
  final Cliente cliente;

  OrdemComCliente({required this.ordem, required this.cliente});
}

// =============================================================================
// CONEXÃO COM O BANCO
// =============================================================================
LazyDatabase _abrirConexao() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'gestor_os.db');
    return NativeDatabase(File(path));
  });
}
