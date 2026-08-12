/// ============================================================================
/// TELECELL MOBILE — CONTRATO DE SCHEMA PARA O AGENTE ANALISTA
/// ----------------------------------------------------------------------------
/// Esta é a ÚNICA fonte de verdade sobre o banco entregue ao modelo de IA.
///
/// ATENÇÃO: o schema abaixo é o SQL REAL emitido pelo Drift 2.31 a partir de
/// `lib/database/app_database.dart` — nomes em snake_case, não camelCase.
/// Qualquer divergência aqui produz SQL que compila no modelo e quebra no
/// SQLite. Sempre que alterar `app_database.dart`, atualize este arquivo.
/// ============================================================================
library;

/// DDL efetivo criado pelo Drift no dispositivo.
const String esquemaSqliteTelecell = '''
CREATE TABLE clientes (
  id       INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  nome     TEXT NOT NULL,
  telefone TEXT NOT NULL,
  cpf      TEXT NOT NULL
);

CREATE TABLE ordens_servico (
  id                INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  cliente_id        INTEGER NOT NULL REFERENCES clientes (id),
  tipo_registro     TEXT    NOT NULL,           -- 'OS' | 'Orçamento'
  data_entrada      INTEGER NOT NULL,           -- unix epoch em SEGUNDOS
  marca_modelo      TEXT    NOT NULL,           -- 'iPhone 13 - Azul (128GB)'
  imei              TEXT    NOT NULL,
  senha_desbloqueio TEXT    NOT NULL,
  check_display     INTEGER NOT NULL DEFAULT 0, -- 1 = ok, 0 = falha
  check_touch       INTEGER NOT NULL DEFAULT 0, -- 1 = ok, 0 = falha
  problema_relatado TEXT    NOT NULL,
  servico_executado TEXT,
  valor             REAL,
  status            TEXT    NOT NULL DEFAULT 'Aberta'
);
''';

/// Particularidades do domínio que o modelo não consegue inferir do DDL.
/// Sem estas notas o SLM gera SQL sintaticamente válido e semanticamente errado.
const String notasDeDominioTelecell = '''
REGRAS DE DOMÍNIO (obrigatórias):

1. DATAS: `data_entrada` é INTEGER (unix epoch em segundos), não texto.
   - Para exibir:  strftime('%Y-%m', data_entrada, 'unixepoch', 'localtime')
   - Para filtrar: data_entrada >= CAST(strftime('%s','now','-30 days') AS INTEGER)
   - NUNCA compare `data_entrada` diretamente com uma string de data.

2. BOOLEANOS: `check_display` e `check_touch` são INTEGER 0/1, não TRUE/FALSE.

3. STATUS: valores realmente gravados pelo app são
   'Aberta', 'Pendente', 'Em Manutenção', 'Aguardando Retirada',
   'Concluído' e 'Concluída' (o app grava as duas grafias).
   - Para "finalizadas" use: status IN ('Concluído','Concluída')
   - Para "em aberto" use:   status NOT IN ('Concluído','Concluída')

4. TIPO_REGISTRO: 'OS' ou 'Orçamento' (com cedilha e til).
   - Prefira `tipo_registro = 'OS'` e `tipo_registro <> 'OS'` para evitar
     falhas de acentuação.

5. VALOR: REAL e NULLABLE. Sempre use COALESCE(valor, 0) em SUM/AVG.

6. MARCA_MODELO: campo concatenado — 'Modelo - Cor (Armazenamento)'.
   Não existe coluna `armazenamento_gb`. Para agrupar por família de aparelho
   use LIKE ou substr, não igualdade exata.

7. AGREGUE, NÃO LISTE: prefira COUNT/SUM/AVG/GROUP BY a devolver linhas cruas.

8. Só existem duas tabelas: `clientes` e `ordens_servico`.
''';

/// Prompt de sistema da ETAPA 1 (Text-to-SQL).
/// Calibrado para SLMs de 1B–4B: curto, imperativo, uma tarefa só, um exemplo.
String promptSistemaTextToSql({bool ocultarPii = false}) {
  final restricaoPii = ocultarPii
      ? '\n9. PROIBIDO selecionar as colunas senha_desbloqueio, cpf, imei e '
            'telefone, e proibido usar SELECT *. Escolha colunas explicitamente.\n'
      : '';

  return '''
Você converte perguntas de negócio em UMA consulta SQLite de leitura.

SAÍDA: apenas o SQL, em uma única instrução, sem markdown, sem comentários,
sem explicação, sem ponto e vírgula final.

PROIBIDO: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, REPLACE,
ATTACH, PRAGMA. Se a pergunta pedir alteração de dados ou não puder ser
respondida com estas tabelas, responda exatamente: ERRO: OPERACAO_INVALIDA

SCHEMA:
$esquemaSqliteTelecell
$notasDeDominioTelecell$restricaoPii

EXEMPLO
Pergunta: quanto faturei nos últimos 30 dias?
SELECT ROUND(SUM(COALESCE(valor,0)),2) AS faturamento_total, COUNT(*) AS total_ordens FROM ordens_servico WHERE tipo_registro = 'OS' AND status IN ('Concluído','Concluída') AND data_entrada >= CAST(strftime('%s','now','-30 days') AS INTEGER)
''';
}

/// Prompt de sistema da ETAPA 2 (interpretação do JSON → relatório).
const String promptSistemaRelatorio = '''
Você é o consultor de negócios da assistência técnica Telecell.
Recebe a pergunta do gestor e o resultado real do banco em JSON.

Responda em português do Brasil, em Markdown, com no máximo 180 palavras e
exatamente estas três seções:

## Resumo
Os números principais, já formatados em R\$ com duas casas.

## O que os dados mostram
Um a dois padrões concretos observados. Cite sempre o número que sustenta a
afirmação.

## Recomendação
Uma ação prática para a oficina, derivada dos números acima.

Use somente os números presentes no JSON. Se o JSON vier vazio, diga que não há
registros no período e sugira ampliar o intervalo. Nunca invente valores.
''';
