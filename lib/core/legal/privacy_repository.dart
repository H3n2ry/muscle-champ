import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'legal_texts.dart';

final privacyRepositoryProvider =
    Provider<PrivacyRepository>((_) => PrivacyRepository());

/// Consentimento vigente de uma finalidade.
class ConsentStatus {
  final String type;
  final bool granted;
  final String documentVersion;
  final DateTime grantedAt;

  const ConsentStatus({
    required this.type,
    required this.granted,
    required this.documentVersion,
    required this.grantedAt,
  });

  /// Verdadeiro quando o consentimento foi dado sobre uma versão antiga dos
  /// documentos — o usuário precisa reconsentir.
  bool get isStale => documentVersion != LegalTexts.documentVersion;
}

/// Operações de direitos do titular (LGPD Art. 18 / GDPR Art. 15-22).
class PrivacyRepository {
  final _client = Supabase.instance.client;

  // ── Acesso e portabilidade ─────────────────────────────────────────────
  /// Baixa tudo que o app guarda sobre o usuário logado.
  Future<Map<String, dynamic>> exportMyData() async {
    final result = await _client.rpc('export_my_data');
    return Map<String, dynamic>.from(result as Map);
  }

  /// Exporta e entrega o arquivo ao usuário (share sheet no mobile).
  ///
  /// Usa [XFile.fromData] em vez de gravar via `dart:io` — `dart:io` não existe
  /// no web e quebraria a compilação. O share_plus materializa o arquivo
  /// temporário sozinho nas plataformas nativas.
  ///
  /// Retorna o JSON serializado para que a UI possa oferecer "copiar" como
  /// alternativa — no web o share sheet não está disponível em todo navegador.
  Future<String> exportAndShare() async {
    final data = await exportMyData();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    if (!kIsWeb) {
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: 'muscle-champ-meus-dados-$stamp.json',
          ),
        ],
        subject: 'Meus dados — Muscle Champ',
      );
    }

    return json;
  }

  // ── Exclusão ───────────────────────────────────────────────────────────
  /// Apaga a conta e todos os dados. Irreversível.
  ///
  /// O avatar é removido **antes**, pela Storage API: o Postgres bloqueia
  /// `DELETE` direto em `storage.objects` (trigger `storage.protect_delete`),
  /// então tentar apagar dentro da função SQL abortava a transação inteira e
  /// nada era excluído.
  ///
  /// Após o sucesso a sessão é encerrada localmente — o usuário do `auth`
  /// já não existe, então qualquer chamada subsequente falharia.
  Future<void> deleteMyAccount() async {
    final userId = _client.auth.currentUser?.id;

    if (userId != null) {
      try {
        final files = await _client.storage.from('avatars').list(path: userId);
        if (files.isNotEmpty) {
          await _client.storage
              .from('avatars')
              .remove(files.map((f) => '$userId/${f.name}').toList());
        }
      } catch (_) {
        // Um avatar órfão não pode impedir o titular de exercer o direito de
        // exclusão (LGPD Art. 18 VI / GDPR Art. 17). Segue para apagar o banco.
      }
    }

    await _client.rpc('delete_my_account');
    await _client.auth.signOut();
  }

  // ── Consentimento ──────────────────────────────────────────────────────
  /// Consentimento vigente por finalidade (o mais recente de cada tipo).
  Future<Map<String, ConsentStatus>> myConsents() async {
    final rows = await _client
        .from('user_consents')
        .select('consent_type, granted, document_version, granted_at')
        .order('granted_at', ascending: false);

    final out = <String, ConsentStatus>{};
    for (final row in (rows as List)) {
      final type = row['consent_type'] as String;
      // A query vem ordenada do mais recente para o mais antigo, então a
      // primeira ocorrência de cada tipo é a vigente.
      if (out.containsKey(type)) continue;
      out[type] = ConsentStatus(
        type: type,
        granted: row['granted'] as bool,
        documentVersion: row['document_version'] as String,
        grantedAt: DateTime.parse(row['granted_at'] as String),
      );
    }
    return out;
  }

  Future<void> grantConsent(String type) => _client.rpc('grant_consent', params: {
        'p_consent_type': type,
        'p_document_version': LegalTexts.documentVersion,
        'p_locale': 'pt-BR',
      });

  Future<void> revokeConsent(String type) =>
      _client.rpc('revoke_consent', params: {'p_consent_type': type});
}

/// Consentimentos vigentes do usuário logado.
final myConsentsProvider =
    FutureProvider.autoDispose<Map<String, ConsentStatus>>((ref) {
  return ref.watch(privacyRepositoryProvider).myConsents();
});
