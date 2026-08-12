import 'dart:convert';

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../core/sql_guard.dart';

/// ============================================================================
/// EXECUTOR DE CONSULTAS SOMENTE LEITURA
/// ----------------------------------------------------------------------------
/// Última fronteira antes do SQLite. Reexecuta o [SqlGuard] mesmo que o
/// chamador já tenha sanitizado — o custo é microssegundos e elimina a chance
/// de um caminho novo no código passar por cima da validação.
/// ============================================================================

class ResultadoConsulta {
  final String sqlExecutado;
  final List<Map<String, Object?>> linhas;
  final String json;
  final bool truncado;
  final Duration duracao;

  const ResultadoConsulta({
    required this.sqlExecutado,
    required this.linhas,
    required this.json,
    required this.truncado,
    required this.duracao,
  });

  bool get vazio => linhas.isEmpty;
}

class ReadOnlyQueryRunner {
  final AppDatabase _db;

  /// Teto de caracteres do JSON devolvido ao modelo. Um SLM local trabalha com
  /// 2k–8k tokens de contexto; estourar isso não gera erro, gera alucinação.
  final int limiteCaracteresJson;

  ReadOnlyQueryRunner(this._db, {this.limiteCaracteresJson = 6000});

  Future<ResultadoConsulta> executar(
    String sql, {
    PoliticaPrivacidade politica = PoliticaPrivacidade.local,
  }) async {
    final segura = SqlGuard.sanitizar(sql, politica: politica);
    final cronometro = Stopwatch()..start();

    late final List<QueryRow> linhasBrutas;
    try {
      linhasBrutas = await _db.customSelect(segura.sql).get();
    } on Object catch (e) {
      // Erro de SQL válido-mas-errado (coluna inexistente, tipo incompatível).
      // Devolvemos algo acionável em vez de vazar o stack trace do sqlite3.
      throw SqlGuardException(
        'O banco recusou a consulta gerada. Detalhe técnico: $e',
        sqlRecebido: segura.sql,
      );
    } finally {
      cronometro.stop();
    }

    final linhas =
        linhasBrutas.map((linha) => _normalizarLinha(linha.data)).toList();

    var json = jsonEncode(linhas);
    var truncado = false;
    if (json.length > limiteCaracteresJson) {
      // Corta por linha (não por caractere) para nunca entregar JSON inválido.
      final reduzidas = <Map<String, Object?>>[];
      var acumulado = 2;
      for (final linha in linhas) {
        final peso = jsonEncode(linha).length + 1;
        if (acumulado + peso > limiteCaracteresJson) break;
        reduzidas.add(linha);
        acumulado += peso;
      }
      json = jsonEncode(reduzidas);
      truncado = true;
    }

    return ResultadoConsulta(
      sqlExecutado: segura.sql,
      linhas: linhas,
      json: json,
      truncado: truncado,
      duracao: cronometro.elapsed,
    );
  }

  /// Converte tipos do SQLite para algo que o modelo interpreta corretamente.
  Map<String, Object?> _normalizarLinha(Map<String, Object?> dados) {
    return dados.map((coluna, valor) {
      if (valor is double) {
        return MapEntry(coluna, double.parse(valor.toStringAsFixed(2)));
      }
      // Colunas de data não convertidas na própria query voltam como epoch.
      // Sem isso o modelo lê "1770854400" e informa isso ao usuário.
      if (valor is int &&
          coluna.contains('data') &&
          valor > 100000000 &&
          valor < 4102444800) {
        final data = DateTime.fromMillisecondsSinceEpoch(valor * 1000);
        return MapEntry(coluna, data.toIso8601String().substring(0, 10));
      }
      return MapEntry(coluna, valor);
    });
  }
}
