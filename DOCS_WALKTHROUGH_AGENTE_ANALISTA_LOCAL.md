# 📱 Telecell Mobile — Agente Analista de Dados 100% Local

| | |
| :--- | :--- |
| **Projeto** | Telecell Mobile — Gestor de OS & Inteligência de Estoque |
| **Módulo** | Agente Analista de Dados (Text-to-SQL offline, somente leitura) |
| **Autor** | Anthy Guedes |
| **Data** | 12 de agosto de 2026 |
| **Versão** | 1.1.0+2 |
| **Stack** | Flutter 3.8+ · Dart 3.8 · Drift 2.31 · SQLite · Material 3 |

---

## 1. Visão Geral

O módulo transforma perguntas em português — *"qual foi meu faturamento no mês?"* — em consultas SQL somente leitura executadas no SQLite local, e devolve um relatório executivo redigido por um modelo de linguagem que roda **dentro do aparelho**, sem rede.

O fluxo tem três estágios, e o estágio do meio é o mais importante:

```
Pergunta em português
        │
        ▼
┌───────────────────────┐
│ ETAPA 1 · Text-to-SQL │  Roteador curado (0 ms) ou SLM local (5–20 s)
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ 🛡️  SQL GUARD          │  6 camadas de validação — nada passa sem revisão
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ ETAPA 2 · Execução    │  Drift customSelect → JSON (com teto de payload)
└───────────┬───────────┘
            ▼
┌───────────────────────┐
│ ETAPA 3 · Relatório   │  JSON + pergunta → Markdown para o gestor
└───────────────────────┘
```

**Objetivo técnico:** manter a promessa *offline-first* que já é o diferencial do Telecell, estendendo-a à camada de inteligência — e garantir, por construção, que nenhuma string gerada por IA possa escrever no banco de produção do cliente.

---

## 2. ⚠️ Correção Crítica Antes de Qualquer Código

O *system prompt* do rascunho descrevia um schema que **não existe** no aplicativo. O Drift converte os identificadores Dart para `snake_case` e materializa tipos diferentes dos assumidos. Um modelo alimentado com o schema errado gera SQL sintaticamente perfeito que falha 100% das vezes no `sqlite3`.

| Item | No rascunho | Real (gerado pelo Drift 2.31) | Impacto se não corrigido |
| :--- | :--- | :--- | :--- |
| Nome da tabela | `OrdensServico` | `ordens_servico` | `no such table` |
| Data de entrada | *(ausente)* | `data_entrada INTEGER` — **unix epoch em segundos** | Todo filtro por período retorna vazio |
| Armazenamento | `armazenamento_gb TEXT` | *(não existe)* — está concatenado em `marca_modelo` | `no such column` |
| `check_display` / `check_touch` | `BOOLEAN` | `INTEGER` 0/1 | `WHERE check_display = TRUE` não filtra |
| Valores de `status` | `'Aguardando Peça'`, `'Entregue'` | `'Aberta'`, `'Pendente'`, `'Em Manutenção'`, `'Aguardando Retirada'`, `'Concluído'`, `'Concluída'` | Consultas de faturamento retornam zero |
| `tipo_registro` | `'Orcamento'` | `'Orçamento'` (com cedilha) | Filtro de orçamentos nunca casa |
| Coluna `imei` | IMEI do aparelho | Na prática recebe o **CPF do cliente** (`cadastro_os_page.dart`) | Análise por IMEI produz resultado sem sentido |

> **Ação recomendada no app:** o campo `imei` gravando CPF é uma dívida técnica que vale endereçar. Enquanto ela existir, `lib/ai/core/telecell_schema.dart` documenta o comportamento para o modelo não interpretar mal.

### O bug de segurança no validador original

O `gemini_analyst_service.dart` verificava termos proibidos com `uppercaseSql.contains(keyword)`. Isso produz **falsos positivos garantidos** neste schema:

```dart
// ❌ Original — 'SERVICO_EXECUTADO'.contains('EXEC') == true
if (uppercaseSql.contains(keyword)) { throw ... }
```

Qualquer consulta que leia `servico_executado` — ou seja, praticamente toda análise de serviços prestados — era bloqueada. E o inverso também acontecia: um cliente cadastrado como *"Update Celulares"* derrubaria a validação.

```dart
// ✅ Corrigido — limite de palavra, sobre o SQL sem literais de string
if (RegExp('\\b$palavra\\b').hasMatch(esqueleto)) { throw ... }
```

---

## 3. Arquivos Impactados

| Arquivo | Tipo | Responsabilidade |
| :--- | :--- | :--- |
| `lib/ai/core/telecell_schema.dart` | 🆕 Novo | Fonte única do schema real + prompts de sistema calibrados |
| `lib/ai/core/sql_guard.dart` | 🆕 Novo | Portão de segurança em 6 camadas entre a IA e o SQLite |
| `lib/ai/core/analyst_engine.dart` | 🆕 Novo | Interface `AnalystEngine` (Strategy) e modelos de status |
| `lib/ai/core/catalogo_consultas.dart` | 🆕 Novo | 8 consultas curadas + roteador determinístico (caminho zero-LLM) |
| `lib/ai/data/read_only_query_runner.dart` | 🆕 Novo | Execução via `customSelect`, serialização JSON, teto de payload |
| `lib/ai/engines/local_llm_engine.dart` | 🆕 Novo | Motor offline (`flutter_gemma` / LiteRT-LM) |
| `lib/ai/engines/gemini_cloud_engine.dart` | 🆕 Novo | Motor em nuvem opcional (Gemini) |
| `lib/ai/config/ai_settings.dart` | 🆕 Novo | Configuração persistida + cofre criptografado da chave |
| `lib/ai/analista_controller.dart` | 🆕 Novo | Orquestrador do fluxo, estados observáveis |
| `lib/screens/configuracoes_ia_page.dart` | 🆕 Novo | Escolha do motor, modelo local, chave de API, teste |
| `lib/screens/analista_ia_page.dart` | 🆕 Novo | Conversa com o agente, auditoria do SQL |
| `test/sql_guard_test.dart` | 🆕 Novo | 15 testes do portão, incluindo regressões |
| `lib/main.dart` | ✏️ Editado | Duas rotas nomeadas |
| `lib/screens/dashboard_page.dart` | ✏️ Editado | Ação rápida "Analista de Dados" |
| `pubspec.yaml` | ✏️ Editado | 5 dependências novas |

Nenhum arquivo da camada de dados existente foi tocado. **`app_database.dart` não muda, logo `build_runner` não é obrigatório para este módulo** — ele aparece no guia de validação apenas por higiene de build.

---

## 4. Detalhamento do Código — Aula Passo a Passo

### 4.1 O contrato: `AnalystEngine`

```dart
abstract class AnalystEngine {
  TipoMotor get tipo;
  Future<StatusMotor> verificarStatus();
  Future<void> preparar();
  Future<String> gerarSql(String pergunta);
  Future<String> gerarRelatorio({required String pergunta, required String resultadoJson});
  Future<void> liberar();
}
```

A UI e o controller nunca mencionam `flutter_gemma` nem `google_generative_ai`. Trocar de motor é instanciar outra classe. Isso é o padrão **Strategy**, e aqui ele resolve um problema concreto: o parque de aparelhos de uma assistência técnica é heterogêneo — um Galaxy A15 de balcão não roda Gemma 4 E2B, mas roda Gemma 3 1B; um tablet mais antigo pode precisar do modo nuvem.

### 4.2 As 6 camadas do `SqlGuard`

| Camada | O que faz | Ataque que impede |
| :---: | :--- | :--- |
| 1 | Remove cercas markdown, crases, comentários `--` e `/* */` | Comando escondido dentro de comentário |
| 2 | Corta no primeiro `;` e recusa se houver conteúdo depois | `SELECT 1; DROP TABLE clientes` |
| 3 | Exige início em `SELECT`/`WITH` e varre palavras proibidas com `\b` **sobre o esqueleto** (SQL sem literais de string) | Escrita direta, sem falso positivo em dados |
| 4 | Allowlist de tabelas (`clientes`, `ordens_servico` + CTEs locais); bloqueia CTE recursiva | `sqlite_master`, `pragma_table_info`, loop infinito |
| 5 | No modo nuvem, bloqueia `SELECT *` e as colunas `cpf`, `imei`, `telefone`, `senha_desbloqueio` | Vazamento de dado pessoal para API externa |
| 6 | Injeta `LIMIT 200` quando ausente | Varredura de tabela inteira; estouro do contexto do SLM |

O truque central é a camada 3. Antes de procurar palavras perigosas, o guard substitui todo literal `'...'` por `''`:

```dart
final esqueleto = sql.replaceAll(_literalString, "''").toUpperCase();
```

Assim `WHERE nome = 'Update Celulares Ltda'` vira `WHERE NOME = ''` — os dados do cliente deixam de participar da análise léxica. É a mesma ideia de separar código de dados que sustenta *prepared statements*.

### 4.3 O roteador de consultas curadas — a decisão mais importante

Um SLM de 1B–4B parâmetros **não é confiável em Text-to-SQL livre**. Ele acerta a sintaxe e erra a semântica: esquece o `COALESCE`, compara epoch com string, inventa o valor `'Entregue'` que nunca existiu neste banco.

Mas a distribuição de perguntas reais numa assistência técnica é fortemente concentrada. Oito perguntas cobrem a maior parte do uso: faturamento, ticket médio, gargalos, modelos mais atendidos, melhores clientes, OS vs orçamento, evolução mensal, defeitos recorrentes.

Então o roteador tenta primeiro um casamento por palavras-chave, com pontuação ponderada pelo tamanho do gatilho:

```dart
for (final gatilho in consulta.gatilhos) {
  if (normalizada.contains(_normalizar(gatilho))) {
    pontuacao += gatilho.length;  // gatilho mais longo = mais específico
  }
}
return melhorPontuacao >= 6 ? melhor : null;  // piso de confiança
```

O SQL dessas oito foi escrito e revisado por humano, e está versionado no repositório. Consequências práticas:

- **Latência:** as perguntas comuns respondem em milissegundos, não em 20 segundos.
- **Confiabilidade:** o caminho mais usado não depende de inferência probabilística.
- **Degradação graciosa:** com o modelo ainda baixando, o app já responde o essencial.
- **O modelo vira exceção, não regra** — e a superfície de erro encolhe na mesma proporção.

O piso de confiança `>= 6` evita que a partícula "os" case com qualquer frase.

### 4.4 Execução e serialização

```dart
final segura = SqlGuard.sanitizar(sql, politica: politica);   // revalida sempre
final linhas = await _db.customSelect(segura.sql).get();
```

O guard roda **de novo** aqui, mesmo que o controller já tenha sanitizado. Custa microssegundos e garante que um caminho novo no código — um botão de "reexecutar", um deep link — não consiga pular a validação. Segurança não deve depender de todo mundo lembrar de chamar a função certa.

Duas normalizações antes de entregar ao modelo:

```dart
if (valor is int && coluna.contains('data') && valor > 100000000 && valor < 4102444800) {
  return MapEntry(coluna, DateTime.fromMillisecondsSinceEpoch(valor * 1000)
      .toIso8601String().substring(0, 10));
}
```

Sem isso o modelo lê `1770854400` e informa esse número ao gestor. E há o teto de payload:

```dart
if (json.length > limiteCaracteresJson) { /* corta por LINHA, não por caractere */ }
```

O corte por linha é deliberado: truncar por caractere entrega JSON inválido, e um SLM que recebe JSON quebrado não gera erro — gera números inventados.

### 4.5 O prompt calibrado para modelo pequeno

Prompt de SLM não é prompt de modelo grande. As regras aplicadas em `promptSistemaTextToSql`:

1. **Uma tarefa por chamada.** Gerar SQL e explicar o resultado são chamadas separadas.
2. **Formato de saída antes do schema.** Modelos pequenos aderem melhor ao que leem primeiro.
3. **Notas de domínio explícitas.** O DDL não conta que `data_entrada` é epoch nem quais valores de `status` existem de fato. Essas oito regras valem mais que o DDL.
4. **Um exemplo, completo.** Vários exemplos consomem a janela de contexto de 2k–8k tokens sem ganho proporcional.
5. **`temperature: 0.1` na etapa 1, `0.4` na etapa 2.** SQL não é tarefa criativa; texto para humano tolera variação.

### 4.6 Privacidade como código, não como promessa

O motor local recebe `PoliticaPrivacidade.local`; o Gemini recebe `.nuvem`. No modo nuvem, `SELECT *` e as quatro colunas de dado pessoal são **bloqueados pelo guard** — não por convenção, por exceção lançada. A tela do analista informa o modo ativo numa faixa permanente no topo.

Isso importa juridicamente: senha de desbloqueio de aparelho e CPF são dado pessoal sob a LGPD, e a assistência técnica é a controladora desses dados.

---

## 5. Decisões de Arquitetura & Rationale

| Decisão | Alternativa descartada | Por quê |
| :--- | :--- | :--- |
| Roteador curado antes do LLM | Text-to-SQL puro | SLM pequeno erra semântica de SQL; 80% das perguntas são as mesmas 8 |
| Validação sobre o esqueleto sem literais | `contains()` no SQL cru | Elimina falso positivo (`servico_executado` ⊃ `EXEC`) e falso negativo |
| Allowlist de tabelas | Só denylist de comandos | Denylist é sempre incompleta; allowlist falha fechado |
| `flutter_secure_storage` para a chave | `SharedPreferences` | SharedPreferences grava XML em texto puro, legível em backup ADB |
| `ChangeNotifier` + `ListenableBuilder` | Riverpod / BLoC | O projeto usa `StatefulWidget`; introduzir um framework de estado por um módulo é imposto arquitetural desnecessário |
| Renderizador Markdown caseiro | `flutter_markdown` | 4 elementos (`##`, `**`, `-`, `>`) já são garantidos pelo prompt; a dependência custaria ~300 KB no APK |
| Toda API do `flutter_gemma` isolada em 3 métodos | Chamadas espalhadas | O pacote evolui rápido; concentrar reduz a atualização a um arquivo |
| `LIMIT 200` injetado | Confiar no modelo | Protege o banco e a janela de contexto do SLM ao mesmo tempo |
| Motor nuvem mantido | Build estritamente offline | Aparelhos de balcão antigos podem não ter RAM; é plano B, não padrão |

### Sobre a escolha do modelo local

| Modelo | RAM | Perfil |
| :--- | :--- | :--- |
| **Gemma 3 1B** (`.task`) | ~1 GB | Aparelho de balcão. Bom em classificação, fraco em SQL livre — depende do roteador curado. |
| **Gemma 4 E2B** (`.litertlm`) | ~3 GB | Aparelho com 6 GB+. Text-to-SQL livre com qualidade aceitável. |

Text-to-SQL é tarefa de precisão: use o maior modelo que o parque de aparelhos suportar, e mantenha as respostas rápidas ligadas nos dois casos.

> **Nota de manutenção.** `flutter_gemma` é um pacote em evolução rápida — a API de sessão mudou entre versões recentes. Se `flutter pub get` trouxer uma versão com assinatura diferente, ajuste apenas `_inicializarRuntime`, `_instalarModelo`, `_abrirModelo` e `_completar` em `local_llm_engine.dart`. O restante do módulo depende só da interface `AnalystEngine`.

---

## 6. Integração no App Existente

### 6.1 `lib/main.dart` — registrar as rotas

```dart
import 'screens/analista_ia_page.dart';
import 'screens/configuracoes_ia_page.dart';

// dentro de routes: { ... }
'/analista-ia':     (context) => const AnalistaIaPage(),
'/configuracoes-ia': (context) => const ConfiguracoesIaPage(),
```

### 6.2 `lib/screens/dashboard_page.dart` — ação rápida

Junto dos atalhos existentes (Nova OS, Novo Orçamento, Clientes, Estoque):

```dart
_buildAcaoRapida(
  icone: Icons.insights_rounded,
  titulo: 'Analista de Dados',
  cor: const Color(0xFFE67E22),
  onTap: () => Navigator.pushNamed(context, '/analista-ia'),
),
```

### 6.3 Android — permissões

O download do modelo (uma vez, por Wi-Fi) precisa de rede. Em `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Só se for usar o backend de GPU. Sem esta linha, o motor cai para CPU. -->
<uses-native-library android:name="libOpenCL.so" android:required="false"/>
```

`minSdkVersion` 26 ou superior.

### 6.4 Modelo local

Publique o `.task` / `.litertlm` num espelho seu ou no Hugging Face e substitua as URLs em `ModeloLocalDisponivel.catalogo`. Para homologação, o campo "caminho do arquivo" na tela de Configurações aceita um modelo já copiado para `/storage/emulated/0/Download/`.

---

## 7. Guia de Validação

### 7.1 Comandos

```bash
# 1. Resolver as dependências novas
flutter pub get

# 2. Regenerar o Drift (não é obrigatório: o schema não mudou.
#    Rode por higiene de build ou se editar app_database.dart depois.)
dart run build_runner build --delete-conflicting-outputs

# 3. Rodar os testes do portão de segurança — falha aqui bloqueia o merge
flutter test test/sql_guard_test.dart

# 4. Análise estática
flutter analyze

# 5. Executar em dispositivo físico (o emulador não tem GPU adequada
#    e a inferência local cai para CPU, ficando lenta)
flutter run --release
```

### 7.2 Checklist de homologação

**Segurança — obrigatório**

- [ ] `flutter test test/sql_guard_test.dart` passa 15/15
- [ ] Pedir ao agente *"apague todas as ordens do mês passado"* → recusa explicada, banco intacto
- [ ] Pedir *"quanto faturei? ; DROP TABLE clientes"* → bloqueio por múltipla instrução
- [ ] Conferir com `sqlite3` que a contagem de linhas não muda depois de 20 perguntas

**Corretude dos dados**

- [ ] "Qual meu faturamento nos últimos 30 dias?" bate com a soma manual no dashboard
- [ ] "Quais modelos eu mais conserto?" bate com a Curva ABC de `inteligencia_estoque_page`
- [ ] Nenhuma resposta exibe timestamp cru (ex.: `1770854400`) no lugar de data
- [ ] Com banco vazio: mensagem de estado vazio, sem exceção

**Privacidade**

- [ ] Modo nuvem + pergunta sobre CPF → bloqueio com orientação para trocar de motor
- [ ] Modo local: aparelho em modo avião responde normalmente após o modelo baixado
- [ ] Chave de API não aparece em `adb shell run-as <pkg> cat shared_prefs/*.xml`

**Experiência**

- [ ] Fases aparecem em sequência ("Traduzindo…" → "Lendo o banco…" → "Montando…")
- [ ] O expansor "Ver a consulta usada" mostra o SQL e o botão Copiar funciona
- [ ] Trocar o motor em Configurações e voltar reflete na faixa do topo, sem reiniciar
- [ ] Perguntas curadas respondem em menos de 1 s

---

## 8. Histórico de Mudanças

| Versão | Data | Autor | Alteração |
| :--- | :--- | :--- | :--- |
| 1.0.0+1 | — | Anthy Guedes | Base: dashboard, OS/OC, clientes, Curva ABC |
| 1.1.0+2 | 12/08/2026 | Anthy Guedes | Agente Analista offline: `SqlGuard`, roteador curado, motores local/nuvem, telas de análise e configuração, 15 testes |

---

## 9. Próximos Passos Sugeridos

1. **Corrigir a dívida do campo `imei`** — passou a receber CPF em `cadastro_os_page.dart`. Uma migração do Drift (`schemaVersion: 2`) separando `imei` e `cpf_snapshot` resolve, e a análise por aparelho passa a fazer sentido.
2. **Telemetria do roteador** — registrar quantas perguntas caem no caminho curado. Se um tema aparecer repetidamente no caminho do LLM, ele merece virar a nona consulta curada.
3. **Alimentar o dashboard com o agente** — os insights do módulo podem virar um card de "Destaque da semana" gerado em background.
4. **Cache de relatório** — mesma pergunta + mesmo estado do banco pode reaproveitar a resposta, economizando 20 s de inferência.

---

### 📄 Como gerar o PDF

Salve este arquivo como `WALKTHROUGH.md` e use um dos caminhos:

```bash
# Opção A — Node
npx markdown-pdf WALKTHROUGH.md

# Opção B — Pandoc (melhor tipografia; requer LaTeX)
pandoc WALKTHROUGH.md -o WALKTHROUGH.pdf \
  --pdf-engine=xelatex -V mainfont="Helvetica" -V geometry:margin=2cm --toc
```

**Opção C — VS Code:** instale a extensão *Markdown PDF*, clique com o botão direito no arquivo e escolha **Markdown PDF: Export (pdf)**.

<p align="center"><b>Telecell Mobile</b> · Documentação técnica interna</p>
