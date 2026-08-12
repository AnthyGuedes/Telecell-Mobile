import 'package:flutter_test/flutter_test.dart';
import 'package:aoo_clientes/ai/core/sql_guard.dart';

/// Testes do portão de segurança. Rodam sem dispositivo, sem banco e sem
/// modelo — é a rede de proteção mais barata do módulo de IA e a que mais
/// importa: um furo aqui é escrita não autorizada no banco do cliente.
void main() {
  group('SqlGuard · consultas legítimas', () {
    test('aceita SELECT simples e injeta LIMIT', () {
      final r = SqlGuard.sanitizar('SELECT COUNT(*) FROM ordens_servico');
      expect(r.sql, contains('LIMIT 200'));
      expect(r.limiteAplicado, isTrue);
    });

    test('preserva LIMIT existente', () {
      final r = SqlGuard.sanitizar(
          'SELECT nome FROM clientes ORDER BY nome LIMIT 5');
      expect(r.limiteAplicado, isFalse);
      expect('LIMIT'.allMatches(r.sql).length, 1);
    });

    test('remove cercas de markdown que o modelo adiciona', () {
      final r = SqlGuard.sanitizar('```sql\nSELECT 1 FROM clientes\n```');
      expect(r.sql, startsWith('SELECT 1 FROM clientes'));
    });

    test('aceita CTE com WITH', () {
      final r = SqlGuard.sanitizar(
        'WITH t AS (SELECT valor FROM ordens_servico) SELECT SUM(valor) FROM t',
      );
      expect(r.sql, contains('WITH'));
    });

    // REGRESSÃO — este é o bug do serviço original: a checagem por `contains`
    // encontrava "EXEC" dentro de "servico_executado" e bloqueava qualquer
    // consulta sobre o serviço realizado.
    test('não confunde servico_executado com o comando EXEC', () {
      expect(
        () => SqlGuard.sanitizar(
            'SELECT servico_executado FROM ordens_servico'),
        returnsNormally,
      );
    });

    // REGRESSÃO — literais de dados não podem disparar o filtro de comandos.
    test('aceita literal de texto contendo palavra proibida', () {
      expect(
        () => SqlGuard.sanitizar(
          "SELECT id FROM ordens_servico WHERE problema_relatado "
          "LIKE '%não atualiza o sistema%'",
        ),
        returnsNormally,
      );
    });
  });

  group('SqlGuard · bloqueios', () {
    void esperaBloqueio(String sql) {
      expect(
        () => SqlGuard.sanitizar(sql),
        throwsA(isA<SqlGuardException>()),
        reason: 'deveria bloquear: $sql',
      );
    }

    test('bloqueia escrita e DDL', () {
      esperaBloqueio('DELETE FROM ordens_servico');
      esperaBloqueio("UPDATE clientes SET nome = 'x'");
      esperaBloqueio('DROP TABLE clientes');
      esperaBloqueio("INSERT INTO clientes (nome) VALUES ('x')");
      esperaBloqueio('CREATE TABLE t (id INTEGER)');
    });

    test('bloqueia injeção por segunda instrução', () {
      esperaBloqueio('SELECT 1 FROM clientes; DROP TABLE clientes');
    });

    test('bloqueia comando escondido em comentário de bloco', () {
      esperaBloqueio('SELECT 1 FROM clientes /* x */ ; DELETE FROM clientes');
    });

    test('bloqueia acesso a tabelas fora do escopo', () {
      esperaBloqueio('SELECT name FROM sqlite_master');
    });

    test('bloqueia PRAGMA e ATTACH', () {
      esperaBloqueio('SELECT * FROM pragma_table_info');
      esperaBloqueio("SELECT 1 FROM clientes WHERE 1=1 ATTACH DATABASE 'x'");
    });

    test('propaga a recusa explícita do agente', () {
      esperaBloqueio('ERRO: OPERACAO_INVALIDA');
    });
  });

  group('SqlGuard · privacidade no modo nuvem', () {
    test('bloqueia SELECT * quando a inferência é remota', () {
      expect(
        () => SqlGuard.sanitizar(
          'SELECT * FROM clientes',
          politica: PoliticaPrivacidade.nuvem,
        ),
        throwsA(isA<SqlGuardException>()),
      );
    });

    test('bloqueia colunas com dado pessoal quando a inferência é remota', () {
      for (final coluna in ['cpf', 'imei', 'telefone', 'senha_desbloqueio']) {
        expect(
          () => SqlGuard.sanitizar(
            'SELECT $coluna FROM ordens_servico',
            politica: PoliticaPrivacidade.nuvem,
          ),
          throwsA(isA<SqlGuardException>()),
          reason: 'coluna $coluna deveria ser bloqueada na nuvem',
        );
      }
    });

    test('permite as mesmas colunas no modo local, mas avisa', () {
      final r = SqlGuard.sanitizar(
        'SELECT cpf FROM clientes',
        politica: PoliticaPrivacidade.local,
      );
      expect(r.avisos, isNotEmpty);
    });
  });
}
