import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'config/ai_settings.dart';
import 'core/analyst_engine.dart';
import 'core/catalogo_consultas.dart';
import 'core/sql_guard.dart';
import 'data/read_only_query_runner.dart';
import 'engines/gemini_cloud_engine.dart';
import 'engines/local_llm_engine.dart';

/// ============================================================================
/// CONTROLLER DO AGENTE ANALISTA
/// ----------------------------------------------------------------------------
/// Orquestra o fluxo completo e expõe cada fase como estado observável, porque
/// no motor local a etapa 1 pode levar 5–20 s: sem feedback granular o usuário
/// acha que o app travou.
///
/// É um ChangeNotifier puro — o projeto usa StatefulWidget + ListenableBuilder,
/// então nenhuma biblioteca de gerenciamento de estado é adicionada.
/// ============================================================================

enum FaseAnalise { ocioso, carregandoModelo, gerandoSql, consultandoBanco, redigindo, pronto, erro }

extension FaseAnaliseX on FaseAnalise {
  String get mensagem => switch (this) {
        FaseAnalise.carregandoModelo => 'Carregando o modelo no aparelho…',
        FaseAnalise.gerandoSql => 'Traduzindo sua pergunta em consulta…',
        FaseAnalise.consultandoBanco => 'Lendo o banco de dados…',
        FaseAnalise.redigindo => 'Montando o relatório…',
        _ => '',
      };
}

class MensagemAnalise {
  final bool doUsuario;
  final String texto;
  final String? sqlExecutado;
  final int? linhasRetornadas;
  final Duration? duracao;
  final bool viaCurada;
  final bool erro;

  const MensagemAnalise({
    required this.doUsuario,
    required this.texto,
    this.sqlExecutado,
    this.linhasRetornadas,
    this.duracao,
    this.viaCurada = false,
    this.erro = false,
  });
}

class AnalistaController extends ChangeNotifier {
  final AppDatabase _db;
  final AiSettingsRepository _repositorio;

  AnalistaController({
    AppDatabase? db,
    AiSettingsRepository? repositorio,
  })  : _db = db ?? AppDatabase(),
        _repositorio = repositorio ?? AiSettingsRepository();

  final List<MensagemAnalise> mensagens = [];
  FaseAnalise fase = FaseAnalise.ocioso;

  AiSettings _settings = const AiSettings();
  AnalystEngine? _motor;
  ReadOnlyQueryRunner? _executor;

  AiSettings get settings => _settings;
  bool get ocupado =>
      fase != FaseAnalise.ocioso &&
      fase != FaseAnalise.pronto &&
      fase != FaseAnalise.erro;

  /// Recarrega configuração e reconstrói o motor. Chamado no initState da tela
  /// e ao voltar de Configurações — trocar de motor não exige reiniciar o app.
  Future<void> sincronizarConfiguracao() async {
    _settings = await _repositorio.carregar();
    await _motor?.liberar();

    if (_settings.motor == TipoMotor.nuvem) {
      _motor = GeminiCloudEngine(apiKey: await _repositorio.lerChaveApi());
    } else {
      final caminho = _settings.modeloLocalCaminho;
      _motor = LocalLlmEngine(
        origemModelo: caminho.isNotEmpty ? caminho : _settings.modeloLocal.url,
        origemLocal: caminho.isNotEmpty,
      );
    }

    _executor = ReadOnlyQueryRunner(_db, limiteCaracteresJson: 6000);
    notifyListeners();
  }

  Future<void> perguntar(String pergunta) async {
    final texto = pergunta.trim();
    if (texto.isEmpty || ocupado) return;

    mensagens.add(MensagemAnalise(doUsuario: true, texto: texto));
    _mudarFase(FaseAnalise.gerandoSql);

    final cronometro = Stopwatch()..start();
    try {
      if (_motor == null || _executor == null) {
        await sincronizarConfiguracao();
      }

      // ── ETAPA 1: obter o SQL ───────────────────────────────────────────────
      // Caminho rápido: consulta curada resolve sem acionar o modelo.
      final curada = _settings.usarConsultasCuradas
          ? CatalogoConsultas.rotear(texto)
          : null;

      String sqlBruto;
      if (curada != null) {
        sqlBruto = curada.sql;
      } else {
        _mudarFase(FaseAnalise.carregandoModelo);
        await _motor!.preparar();
        _mudarFase(FaseAnalise.gerandoSql);
        sqlBruto = await _motor!.gerarSql(texto);
      }

      // ── ETAPA 2: executar com o guard no caminho ───────────────────────────
      _mudarFase(FaseAnalise.consultandoBanco);
      final resultado = await _executor!.executar(
        sqlBruto,
        politica: _settings.motor.politica,
      );

      if (resultado.vazio) {
        cronometro.stop();
        mensagens.add(MensagemAnalise(
          doUsuario: false,
          texto: 'Não encontrei nenhum registro que atenda a essa pergunta. '
              'Tente ampliar o período ou conferir se as ordens já foram '
              'marcadas como concluídas.',
          sqlExecutado: resultado.sqlExecutado,
          linhasRetornadas: 0,
          duracao: cronometro.elapsed,
          viaCurada: curada != null,
        ));
        _mudarFase(FaseAnalise.pronto);
        return;
      }

      // ── ETAPA 3: números viram relatório ──────────────────────────────────
      _mudarFase(FaseAnalise.redigindo);
      await _motor!.preparar();
      var relatorio = await _motor!.gerarRelatorio(
        pergunta: texto,
        resultadoJson: resultado.json,
      );

      if (resultado.truncado) {
        relatorio += '\n\n> Os dados foram limitados às primeiras linhas para '
            'caber na análise. Peça um recorte menor para ver o restante.';
      }

      cronometro.stop();
      mensagens.add(MensagemAnalise(
        doUsuario: false,
        texto: relatorio,
        sqlExecutado: resultado.sqlExecutado,
        linhasRetornadas: resultado.linhas.length,
        duracao: cronometro.elapsed,
        viaCurada: curada != null,
      ));
      _mudarFase(FaseAnalise.pronto);
    } on SqlGuardException catch (e) {
      _registrarErro(e.motivo);
    } on MotorIndisponivelException catch (e) {
      _registrarErro(e.motivo);
    } on Object catch (e) {
      _registrarErro('Algo deu errado durante a análise: $e');
    }
  }

  void limparHistorico() {
    mensagens.clear();
    fase = FaseAnalise.ocioso;
    notifyListeners();
  }

  void _mudarFase(FaseAnalise nova) {
    fase = nova;
    notifyListeners();
  }

  void _registrarErro(String mensagem) {
    mensagens.add(MensagemAnalise(
      doUsuario: false,
      texto: mensagem,
      erro: true,
    ));
    _mudarFase(FaseAnalise.erro);
  }

  @override
  void dispose() {
    _motor?.liberar();
    super.dispose();
  }
}
