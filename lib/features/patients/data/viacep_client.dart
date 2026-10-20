import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Endereço devolvido pelo ViaCEP, já reduzido aos campos que o formulário
/// do paciente usa. Qualquer campo pode vir vazio (CEPs genéricos de cidade,
/// por exemplo, não têm logradouro nem bairro).
class ViaCepAddress {
  const ViaCepAddress({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory ViaCepAddress.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key]?.toString() ?? '').trim();
    return ViaCepAddress(
      rua: read('logradouro'),
      bairro: read('bairro'),
      cidade: read('localidade'),
      estado: read('uf'),
    );
  }

  final String rua;
  final String bairro;
  final String cidade;
  final String estado;
}

enum CepLookupFailure {
  /// O CEP não tem 8 dígitos.
  invalid,

  /// Formato válido, mas o ViaCEP não conhece o CEP.
  notFound,

  /// Sem resposta dentro do tempo limite.
  timeout,

  /// Falha de conexão, status HTTP inesperado ou resposta ilegível.
  network,
}

class CepLookupException implements Exception {
  const CepLookupException(this.failure);

  final CepLookupFailure failure;

  @override
  String toString() => 'CepLookupException($failure)';
}

/// Consulta https://viacep.com.br/ws/{cep}/json/.
///
/// É só uma ajuda de preenchimento: quem chama deve manter os campos de
/// endereço editáveis e tratar [CepLookupException] como "preencha à mão".
class ViaCepClient {
  ViaCepClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 6),
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// [cep] pode vir com ou sem máscara.
  Future<ViaCepAddress> lookup(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw const CepLookupException(CepLookupFailure.invalid);
    }

    final http.Response response;
    try {
      response = await _client
          .get(Uri.https('viacep.com.br', '/ws/$digits/json/'))
          .timeout(timeout);
    } on TimeoutException {
      throw const CepLookupException(CepLookupFailure.timeout);
    } catch (_) {
      throw const CepLookupException(CepLookupFailure.network);
    }

    // O ViaCEP responde 400 para formato inválido; para CEP bem formado
    // mas inexistente, responde 200 com {"erro": true}.
    if (response.statusCode == 400) {
      throw const CepLookupException(CepLookupFailure.invalid);
    }
    if (response.statusCode != 200) {
      throw const CepLookupException(CepLookupFailure.network);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw const CepLookupException(CepLookupFailure.network);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CepLookupException(CepLookupFailure.network);
    }

    final erro = decoded['erro'];
    if (erro == true || erro == 'true') {
      throw const CepLookupException(CepLookupFailure.notFound);
    }

    return ViaCepAddress.fromJson(decoded);
  }
}
