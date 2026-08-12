/// ============================================================================
/// SQL GUARD — Portão de segurança entre a IA e o SQLite
/// ----------------------------------------------------------------------------
/// Nenhuma string gerada por modelo de linguagem chega ao banco sem passar por
/// aqui. O guard trabalha em camadas (defense in depth): cada verificação
/// isolada é falível; juntas, o custo de burlar é alto.
///
/// Decisão-chave: as validações rodam sobre o "esqueleto" da consulta — o SQL
/// com literais de string e comentários removidos. Sem isso, um cliente
/// chamado "Delete Ltda" derrubaria a consulta por falso positivo.
/// ============================================================================
library;

/// Política de privacidade aplicada à consulta.
enum PoliticaPrivacidade {
  /// Inferência 100% no dispositivo: nenhum dado sai do aparelho.
  local,

  /// Inferência em nuvem: colunas com dado pessoal são bloqueadas.
  nuvem,
}

class SqlGuardException implements Exception {
  final String motivo;
  final String? sqlRecebido;

  const SqlGuardException(this.motivo, {this.sqlRecebido});

  @override
  String toString() => motivo;
}

class ConsultaSegura {
  final String sql;
  final bool limiteAplicado;
  final List<String> avisos;

  const ConsultaSegura({
    required this.sql,
    required this.limiteAplicado,
    this.avisos = const [],
  });
}

class SqlGuard {
  SqlGuard._();

  static const Set<String> _tabelasPermitidas = {'clientes', 'ordens_servico'};

  /// Palavras que caracterizam escrita, DDL ou fuga do sandbox.
  static const Set<String> _palavrasProibidas = {
    'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER', 'CREATE', 'TRUNCATE',
    'REPLACE', 'MERGE', 'UPSERT', 'RETURNING', 'ATTACH', 'DETACH', 'PRAGMA',
    'VACUUM', 'REINDEX', 'ANALYZE', 'GRANT', 'REVOKE', 'EXEC', 'EXECUTE',
    'INTO',
  };

  /// Colunas que carregam dado pessoal do cliente.
  static const Set<String> _colunasSensiveis = {
    'senha_desbloqueio', 'cpf', 'imei', 'telefone',
  };

  static final RegExp _fenceMarkdown = RegExp(r'```[a-zA-Z]*');
  static final RegExp _literalString = RegExp(r"'(?:[^']|'')*'");
  static final RegExp _comentarioLinha = RegExp(r'--[^\n]*');
  static final RegExp _comentarioBloco = RegExp(r'/\*.*?\*/', dotAll: true);
  static final RegExp _origemTabela =
      RegExp(r'\b(?:FROM|JOIN)\s+([a-zA-Z_][\w]*)', caseSensitive: false);
  static final RegExp _nomeCte =
      RegExp(r'\b([a-zA-Z_][\w]*)\s+AS\s*\(', caseSensitive: false);
  static final RegExp _espacos = RegExp(r'\s+');

  /// Valida e normaliza a consulta. Lança [SqlGuardException] se reprovar.
  ///
  /// [limiteMaximoLinhas] é injetado quando o modelo esquece o LIMIT — protege
  /// tanto o banco quanto a janela de contexto do SLM na etapa 2.
  static ConsultaSegura sanitizar(
    String sqlBruto, {
    PoliticaPrivacidade politica = PoliticaPrivacidade.local,
    int limiteMaximoLinhas = 200,
  }) {
    final avisos = <String>[];

    // ── Camada 1: limpeza do envelope que o modelo costuma adicionar ─────────
    var sql = sqlBruto
        .replaceAll(_fenceMarkdown, '')
        .replaceAll('`', '')
        .trim();

    if (sql.toUpperCase().contains('ERRO: OPERACAO_INVALIDA')) {
      throw SqlGuardException(
        'O agente recusou a pergunta: ela não pode ser respondida em modo '
        'somente leitura sobre clientes e ordens de serviço.',
        sqlRecebido: sqlBruto,
      );
    }

    sql = sql
        .replaceAll(_comentarioBloco, ' ')
        .replaceAll(_comentarioLinha, ' ')
        .replaceAll(_espacos, ' ')
        .trim();

    // ── Camada 2: uma instrução, e apenas uma ───────────────────────────────
    final partes = sql.split(';');
    if (partes.length > 1 && partes.sublist(1).any((p) => p.trim().isNotEmpty)) {
      throw SqlGuardException(
        'Bloqueado: a consulta contém mais de uma instrução SQL.',
        sqlRecebido: sqlBruto,
      );
    }
    sql = partes.first.trim();

    if (sql.isEmpty) {
      throw SqlGuardException(
        'O agente não retornou nenhuma consulta. Reformule a pergunta com um '
        'período ou uma métrica específica.',
        sqlRecebido: sqlBruto,
      );
    }

    // ── Camada 3: esqueleto (sem literais) para análise léxica ──────────────
    final esqueleto = sql.replaceAll(_literalString, "''").toUpperCase();

    if (!esqueleto.startsWith('SELECT') && !esqueleto.startsWith('WITH')) {
      throw SqlGuardException(
        'Bloqueado: apenas consultas SELECT são permitidas.',
        sqlRecebido: sqlBruto,
      );
    }

    for (final palavra in _palavrasProibidas) {
      // \b evita o falso positivo clássico: "EXEC" dentro de
      // "servico_executado" derrubaria toda consulta que lê o serviço feito.
      if (RegExp('\\b$palavra\\b').hasMatch(esqueleto)) {
        throw SqlGuardException(
          'Bloqueado: comando de escrita "$palavra" detectado na consulta.',
          sqlRecebido: sqlBruto,
        );
      }
    }

    // ── Camada 4: allowlist de tabelas ──────────────────────────────────────
    // CTE recursiva pode girar indefinidamente e travar a thread do SQLite no
    // aparelho. Nenhuma métrica da Telecell precisa disso.
    if (RegExp(r'\bWITH\s+RECURSIVE\b').hasMatch(esqueleto)) {
      throw SqlGuardException(
        'Bloqueado: consultas recursivas não são permitidas.',
        sqlRecebido: sqlBruto,
      );
    }

    // Nomes de CTE declarados na própria query entram na allowlist local,
    // senão `WITH t AS (...) SELECT ... FROM t` seria reprovado.
    final permitidas = {
      ..._tabelasPermitidas,
      ..._nomeCte
          .allMatches(sql)
          .map((m) => m.group(1)!.toLowerCase()),
    };

    for (final m in _origemTabela.allMatches(sql)) {
      final tabela = m.group(1)!.toLowerCase();
      if (!permitidas.contains(tabela)) {
        throw SqlGuardException(
          'Bloqueado: a tabela "$tabela" não faz parte do escopo de análise.',
          sqlRecebido: sqlBruto,
        );
      }
    }

    // ── Camada 5: privacidade (só morde no modo nuvem) ──────────────────────
    if (politica == PoliticaPrivacidade.nuvem) {
      final selecaoAmpla = RegExp(r'SELECT\s+\*|\.\s*\*').hasMatch(esqueleto);
      if (selecaoAmpla) {
        throw SqlGuardException(
          'Bloqueado no modo nuvem: SELECT * enviaria dados pessoais do '
          'cliente para fora do aparelho. Peça colunas específicas ou troque '
          'para o motor local em Configurações.',
          sqlRecebido: sqlBruto,
        );
      }
      for (final coluna in _colunasSensiveis) {
        if (RegExp('\\b$coluna\\b', caseSensitive: false).hasMatch(sql)) {
          throw SqlGuardException(
            'Bloqueado no modo nuvem: a coluna "$coluna" contém dado pessoal '
            'e não pode ser enviada para a API externa. Use o motor local.',
            sqlRecebido: sqlBruto,
          );
        }
      }
    } else {
      for (final coluna in _colunasSensiveis) {
        if (RegExp('\\b$coluna\\b', caseSensitive: false).hasMatch(sql)) {
          avisos.add('A consulta lê a coluna sensível "$coluna".');
        }
      }
    }

    // ── Camada 6: teto de linhas ────────────────────────────────────────────
    var limiteAplicado = false;
    if (!RegExp(r'\bLIMIT\b').hasMatch(esqueleto)) {
      sql = '$sql LIMIT $limiteMaximoLinhas';
      limiteAplicado = true;
    }

    return ConsultaSegura(
      sql: sql,
      limiteAplicado: limiteAplicado,
      avisos: avisos,
    );
  }
}
