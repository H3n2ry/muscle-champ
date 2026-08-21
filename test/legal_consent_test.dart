import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/legal/legal_documents.dart';
import 'package:muscle_camp/l10n/app_localizations.dart';
import 'package:muscle_camp/core/legal/legal_texts.dart';
import 'package:muscle_camp/shared/widgets/legal_document_sheet.dart';

void main() {
  group('LegalTexts — barreira de idade', () {
    test('idade é calculada em anos completos', () {
      final hoje = DateTime(2026, 8, 17);
      // Aniversário ainda não chegou este ano
      expect(LegalTexts.ageFrom(DateTime(2000, 12, 31), on: hoje), 25);
      // Aniversário foi hoje
      expect(LegalTexts.ageFrom(DateTime(2000, 8, 17), on: hoje), 26);
      // Aniversário foi ontem
      expect(LegalTexts.ageFrom(DateTime(2000, 8, 16), on: hoje), 26);
      // Aniversário é amanhã
      expect(LegalTexts.ageFrom(DateTime(2000, 8, 18), on: hoje), 25);
    });

    test('exatamente na idade mínima é aceito', () {
      final nasc = DateTime(
          DateTime.now().year - LegalTexts.minimumAge,
          DateTime.now().month,
          DateTime.now().day);
      expect(LegalTexts.isOldEnough(nasc), isTrue);
    });

    test('um dia antes de completar a idade mínima é recusado', () {
      final agora = DateTime.now();
      final nasc = DateTime(
          agora.year - LegalTexts.minimumAge, agora.month, agora.day)
          .add(const Duration(days: 1));
      expect(LegalTexts.isOldEnough(nasc), isFalse);
    });

    test('menor claramente abaixo é recusado', () {
      expect(LegalTexts.isOldEnough(DateTime(2020, 1, 1)), isFalse);
    });
  });

  group('LegalTexts — consentimentos do cadastro', () {
    test('termos, privacidade e dados de saúde são obrigatórios', () {
      final obrigatorios = LegalTexts.signupConsents
          .where((c) => c.required)
          .map((c) => c.type)
          .toSet();
      expect(obrigatorios, {'terms', 'privacy', 'health_data'});
    });

    test('foto por IA e marketing são opcionais', () {
      // Consentimento não pode ser condicionado ao que não é necessário
      // para o serviço (GDPR Art. 7(4)).
      final opcionais = LegalTexts.signupConsents
          .where((c) => !c.required)
          .map((c) => c.type)
          .toSet();
      expect(opcionais, {'ai_photo_transfer', 'marketing'});
    });

    test('só termos e privacidade têm documento associado', () {
      expect(LegalDocuments.forConsent('terms'), isNotNull);
      expect(LegalDocuments.forConsent('privacy'), isNotNull);
      expect(LegalDocuments.forConsent('health_data'), isNull);
      expect(LegalDocuments.forConsent('marketing'), isNull);
    });

    test('documentos têm conteúdo real, não placeholder', () {
      for (final doc in [LegalDocuments.terms, LegalDocuments.privacy]) {
        expect(doc.sections.length, greaterThan(5),
            reason: '${doc.title} tem poucas seções');
        for (final s in doc.sections) {
          expect(s.heading.trim(), isNotEmpty);
          expect(s.body.trim().length, greaterThan(20),
              reason: 'Seção "${s.heading}" de ${doc.title} está vazia demais');
        }
      }
    });
  });

  group('LegalDocumentSheet — gate de rolagem', () {
    Future<bool?> abrir(WidgetTester tester, LegalDocument doc,
        {bool showAccept = true}) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'), // asserções abaixo são no texto em português
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await LegalDocumentSheet.show(context, doc,
                      showAcceptButton: showAccept);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return resultado;
    }

    testWidgets('abre com o título e a versão do documento', (tester) async {
      await abrir(tester, LegalDocuments.terms);
      expect(find.text('Termos de Uso'), findsOneWidget);
      expect(find.text('Versão ${LegalTexts.documentVersion}'), findsOneWidget);
    });

    testWidgets('botão de aceite começa desabilitado e pede rolagem',
        (tester) async {
      await abrir(tester, LegalDocuments.privacy);

      expect(find.text('Role até o fim para aceitar'), findsOneWidget);

      final botao = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'LI E ACEITO'),
      );
      expect(botao.onPressed, isNull, reason: 'deveria estar desabilitado');
    });

    testWidgets('rolar até o fim habilita o aceite', (tester) async {
      await abrir(tester, LegalDocuments.privacy);

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();

      expect(find.text('Role até o fim para aceitar'), findsNothing);

      final botao = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'LI E ACEITO'),
      );
      expect(botao.onPressed, isNotNull, reason: 'deveria estar habilitado');
    });

    testWidgets('aceitar retorna true', (tester) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'), // asserções abaixo são no texto em português
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await LegalDocumentSheet.show(
                      context, LegalDocuments.terms);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'LI E ACEITO'));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
    });

    testWidgets('fechar sem aceitar não retorna true', (tester) async {
      bool? resultado;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('pt'), // asserções abaixo são no texto em português
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await LegalDocumentSheet.show(
                      context, LegalDocuments.terms);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(resultado, isNot(isTrue));
    });

    testWidgets('modo leitura não mostra botão de aceite', (tester) async {
      await abrir(tester, LegalDocuments.privacy, showAccept: false);
      expect(find.text('LI E ACEITO'), findsNothing);
      expect(find.text('Role até o fim para aceitar'), findsNothing);
    });
  });
}
