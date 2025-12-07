import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/backend_service.dart';
import 'providers/favorites_provider.dart';
import 'screens/splash_screen.dart'; 

/// Ponto de entrada da aplicação.
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Instância única do serviço de backend usada pela aplicação.
  final backend = BackendService();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        // O provider que gerencia a lista de favoritos e passa a dependência do backend.
        final p = FavoritesProvider(backend: backend);

        // Carrega os favoritos assim que o provider é criado.
        // loadFavorites() é assíncrono
        p.loadFavorites();

        // Retorna o provider para que o Provider monte-o e forneça via contexto.
        return p;
      },
      child: MaterialApp(
        title: 'OpenLibrary App',
        debugShowCheckedModeBanner: false, // remove a tag "debug" 
        theme: ThemeData(
          primarySwatch: Colors.indigo, // cor principal do tema
          visualDensity: VisualDensity.adaptivePlatformDensity, // densidade visual adaptativa
        ),
        // A tela inicial definida é o SplashScreen (seu splash customizado).
        home: SplashScreen(),
      ),
    );
  }
}
