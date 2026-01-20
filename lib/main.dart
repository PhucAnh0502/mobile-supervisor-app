import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:gr2/screens/device_info_screen.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/services/storage_service.dart';
import 'package:gr2/screens/registration_screen.dart';
import 'package:gr2/screens/intro_screen.dart';
import 'package:gr2/services/background_service.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Info App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEB420F)),
        primaryColor: const Color(0xFFEB420F),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEB420F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _ready = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final deviceService = DeviceInfoService();
    
    await deviceService.requestPermission(); 

    try {
      await initializeBackgroundService();
    } catch (_) {
      print("Không thể khởi tạo Background Service");
    }

    final isFirst = await StorageService().isFirstLaunch();
    
    if (mounted) {
      setState(() {
        _isFirst = isFirst;
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Always show the intro on app start; IntroScreen will route to registration
    return const IntroScreen();
  }
}