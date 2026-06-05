import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const EcoMeshApp());
}

class EcoMeshApp extends StatelessWidget {
  const EcoMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(apiBaseUrl: 'http://127.0.0.1:8000'),
      child: MaterialApp(
        title: 'EcoMesh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Nunito',
          colorScheme:
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF4DB8FF),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF2BA3EC),
                secondary: const Color(0xFF00D4AA),
                surface: Colors.white,
              ),
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
