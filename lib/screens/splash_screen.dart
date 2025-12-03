import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart'; // troque pelo seu destino real

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Tempo exibindo splash antes de ir para a Home
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo do Splash
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Círculo maior translúcido
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),

            // Fundo branco atrás da imagem → remove transparência
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white, // fundo preenchido (Opção A)
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16), // opcional
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
