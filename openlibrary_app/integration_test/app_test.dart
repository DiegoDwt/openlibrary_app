import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openlibrary_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:openlibrary_app/widgets/book_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fluxo end-to-end: favoritar e verificar tela de favoritos', (WidgetTester tester) async {
    // Inicia a aplicação
    app.main();
    await tester.pumpAndSettle();

    // Dá um tempo extra para splash / inicializações (ajuste se seu splash for maior)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Opcional: tenta abrir aba de busca se existir navegação com Key('nav_search')
    final searchTab = find.byKey(const Key('nav_search'));
    if (searchTab.evaluate().isNotEmpty) {
      await tester.tap(searchTab.first);
      await tester.pumpAndSettle();
    }

    // ----- localizar campo de busca com checagens robustas -----
    final searchFieldByKey = find.byKey(const Key('search_field'));
    final searchFieldByType = find.byType(TextField);

    Finder effectiveSearchFieldFinder;
    if (searchFieldByKey.evaluate().isNotEmpty) {
      effectiveSearchFieldFinder = searchFieldByKey;
    } else if (searchFieldByType.evaluate().isNotEmpty) {
      effectiveSearchFieldFinder = searchFieldByType;
    } else {
      // DEBUG: lista os widgets na árvore para auxiliar diagnóstico
      print('--- DEBUG: árvore de widgets presentes (tipo / key / texto quando aplicável) ---');
      for (final widget in tester.allWidgets) {
        final keyStr = widget.key?.toString() ?? '';
        final typeStr = widget.runtimeType.toString();
        String textSnippet = '';
        if (widget is Text) {
          textSnippet = ' -> "${widget.data ?? widget.textSpan?.toPlainText() ?? ''}"';
        }
        print('$typeStr $keyStr $textSnippet');
      }
      print('--- FIM DO DUMP ---');

      // Mensagem de falha com instruções práticas
      fail(
        'Campo de busca não encontrado. Certifique-se de que um TextField está presente na tela de busca.\n'
        'Dicas:\n'
        '- Confirme que você editou e está rodando a versão atual do app que contém Key(\'search_field\') no TextField.\n'
        '- Se a SearchScreen não for a tela inicial, adicione Key(\'nav_search\') ao controle que abre a tela e o teste tentará tocar nele.\n'
        '- Se houver um splash longo, aumente o pumpAndSettle inicial.\n'
        'O dump acima mostra os widgets presentes no momento — verifique o console para identificar o campo correto.'
      );
    }

    // Agora usamos a Key/Tipo encontrado com segurança
    final effectiveSearchField = effectiveSearchFieldFinder.first;

    // Preenche com um termo (ajuste se quiser outro)
    await tester.enterText(effectiveSearchField, 'Dune');
    await tester.pumpAndSettle();

    // Localiza botão Buscar (Key preferencial, depois texto)
    final searchButtonByKey = find.byKey(const Key('search_button'));
    final searchButtonByText = find.text('Buscar');

    Finder effectiveSearchButtonFinder;
    if (searchButtonByKey.evaluate().isNotEmpty) {
      effectiveSearchButtonFinder = searchButtonByKey;
    } else if (searchButtonByText.evaluate().isNotEmpty) {
      effectiveSearchButtonFinder = searchButtonByText;
    } else {
      // Dump rápido se não achar o botão
      print('--- DEBUG: widgets (procura botão Buscar) ---');
      for (final widget in tester.allWidgets) {
        if (widget is Text) {
          print('Text: "${widget.data}" key=${widget.key}');
        }
      }
      fail('Botão Buscar não encontrado. Adicione Key(\'search_button\') ou verifique o rótulo do botão.');
    }

    await tester.tap(effectiveSearchButtonFinder.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ------- restante do fluxo (localizar BookCard, fav_button e navegar p/ favoritos) -------
    Finder bookFinder = find.byKey(const Key('book_0'));
    if (bookFinder.evaluate().isEmpty) {
      bookFinder = find.byType(BookCard);
    }
    if (bookFinder.evaluate().isEmpty) {
      fail('Após a busca, nenhum BookCard foi encontrado. Verifique se a busca retornou resultados.');
    }
    final targetBook = bookFinder.first;

    final favButtonInside = find.descendant(of: targetBook, matching: find.byKey(const Key('fav_button')));
    Finder favFinder = favButtonInside;
    if (favFinder.evaluate().isEmpty) {
      favFinder = find.byKey(const Key('fav_button'));
    }
    if (favFinder.evaluate().isEmpty) {
      favFinder = find.widgetWithIcon(IconButton, Icons.favorite_border);
      if (favFinder.evaluate().isEmpty) {
        favFinder = find.widgetWithIcon(IconButton, Icons.favorite);
      }
    }
    if (favFinder.evaluate().isEmpty) {
      fail('Botão de favoritar não encontrado. Garanta que BookCard renderize IconButton com Key("fav_button").');
    }
    await tester.tap(favFinder.first);
    await tester.pumpAndSettle();

    Finder favTab = find.byKey(const Key('nav_favorites'));
    if (favTab.evaluate().isEmpty) favTab = find.textContaining('Favorit', findRichText: false);
    if (favTab.evaluate().isEmpty) favTab = find.byIcon(Icons.favorite);
    if (favTab.evaluate().isEmpty) {
      fail('Não foi possível localizar controle para abrir a tela de Favoritos. Adicione Key("nav_favorites") ou ajuste o teste.');
    }
    await tester.tap(favTab.first);
    await tester.pumpAndSettle();

    final favoritesListItem = find.byType(BookCard);
    expect(favoritesListItem, findsWidgets, reason: 'Nenhum BookCard encontrado na tela de favoritos.');
  });
}
