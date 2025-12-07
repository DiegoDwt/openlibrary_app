import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/backend_service.dart';
import 'providers/favorites_provider.dart';
import 'screens/splash_screen.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final backend = BackendService();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final p = FavoritesProvider(backend: backend);
        p.loadFavorites();
        return p;
      },
      child: MaterialApp(
        title: 'OpenLibrary App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(), // inicia usando seu splash customizado
      ),
    );
  }
}
