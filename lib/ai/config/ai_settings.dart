import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analyst_engine.dart';

/// ============================================================================
/// CONFIGURAÇÃO DO MÓDULO DE IA
/// ----------------------------------------------------------------------------
/// Separação deliberada de armazenamento:
///  • chave de API  → flutter_secure_storage (Keystore/Keychain, criptografado)
///  • preferências  → shared_preferences (não é segredo, e lê de forma síncrona)
/// Guardar a chave em SharedPreferences a deixaria em texto puro num XML
/// legível por qualquer backup ADB de aparelho com root.
/// ============================================================================

/// Catálogo de modelos locais homologados para o Telecell.
class ModeloLocalDisponivel {
  final String id;
  final String nome;
  final String url;
  final String requisito;

  const ModeloLocalDisponivel({
    required this.id,
    required this.nome,
    required this.url,
    required this.requisito,
  });

  static const List<ModeloLocalDisponivel> catalogo = [
    ModeloLocalDisponivel(
      id: 'gemma3-1b',
      nome: 'Gemma 3 1B (leve)',
      // Substitua pela URL do seu espelho / Hugging Face.
      url: 'https://huggingface.co/<org>/<repo>/resolve/main/gemma3-1b-it.task',
      requisito: '~1 GB de RAM livre · roda em aparelhos de balcão',
    ),
    ModeloLocalDisponivel(
      id: 'gemma4-e2b',
      nome: 'Gemma 4 E2B (recomendado)',
      url: 'https://huggingface.co/<org>/<repo>/resolve/main/gemma-4-E2B-it.litertlm',
      requisito: '~3 GB de RAM livre · aparelho com 6 GB ou mais',
    ),
  ];
}

class AiSettings {
  final TipoMotor motor;
  final String modeloLocalId;
  final String modeloLocalCaminho;
  final bool usarConsultasCuradas;
  final int limiteLinhas;

  const AiSettings({
    this.motor = TipoMotor.local,
    this.modeloLocalId = 'gemma3-1b',
    this.modeloLocalCaminho = '',
    this.usarConsultasCuradas = true,
    this.limiteLinhas = 200,
  });

  AiSettings copyWith({
    TipoMotor? motor,
    String? modeloLocalId,
    String? modeloLocalCaminho,
    bool? usarConsultasCuradas,
    int? limiteLinhas,
  }) {
    return AiSettings(
      motor: motor ?? this.motor,
      modeloLocalId: modeloLocalId ?? this.modeloLocalId,
      modeloLocalCaminho: modeloLocalCaminho ?? this.modeloLocalCaminho,
      usarConsultasCuradas: usarConsultasCuradas ?? this.usarConsultasCuradas,
      limiteLinhas: limiteLinhas ?? this.limiteLinhas,
    );
  }

  ModeloLocalDisponivel get modeloLocal =>
      ModeloLocalDisponivel.catalogo.firstWhere(
        (m) => m.id == modeloLocalId,
        orElse: () => ModeloLocalDisponivel.catalogo.first,
      );
}

class AiSettingsRepository {
  static const _chaveApi = 'telecell_gemini_api_key';
  static const _prefMotor = 'telecell_ia_motor';
  static const _prefModelo = 'telecell_ia_modelo_local';
  static const _prefCaminho = 'telecell_ia_modelo_caminho';
  static const _prefCuradas = 'telecell_ia_consultas_curadas';

  final FlutterSecureStorage _cofre;

  AiSettingsRepository({FlutterSecureStorage? cofre})
      : _cofre = cofre ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<AiSettings> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    return AiSettings(
      motor: prefs.getString(_prefMotor) == 'nuvem'
          ? TipoMotor.nuvem
          : TipoMotor.local,
      modeloLocalId: prefs.getString(_prefModelo) ?? 'gemma3-1b',
      modeloLocalCaminho: prefs.getString(_prefCaminho) ?? '',
      usarConsultasCuradas: prefs.getBool(_prefCuradas) ?? true,
    );
  }

  Future<void> salvar(AiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefMotor,
      settings.motor == TipoMotor.nuvem ? 'nuvem' : 'local',
    );
    await prefs.setString(_prefModelo, settings.modeloLocalId);
    await prefs.setString(_prefCaminho, settings.modeloLocalCaminho);
    await prefs.setBool(_prefCuradas, settings.usarConsultasCuradas);
  }

  Future<String> lerChaveApi() async =>
      await _cofre.read(key: _chaveApi) ?? '';

  Future<void> salvarChaveApi(String chave) async {
    final limpa = chave.trim();
    if (limpa.isEmpty) {
      await _cofre.delete(key: _chaveApi);
    } else {
      await _cofre.write(key: _chaveApi, value: limpa);
    }
  }

  /// Mostra só o suficiente para o usuário reconhecer a chave sem expô-la.
  static String mascarar(String chave) {
    if (chave.length <= 8) return '••••••••';
    return '${chave.substring(0, 4)}••••••••${chave.substring(chave.length - 4)}';
  }
}
