import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:gr2/screens/device_info_screen.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/services/storage_service.dart';
import 'package:gr2/screens/registration_screen.dart';

void main(List<String> args) {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Info App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: StorageService().isFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isFirst = snapshot.data ?? true;
          if (isFirst) {
            return const RegistrationScreen();
          }

          return BlocProvider(
            create: (context) => DeviceInfoBloc(DeviceInfoService()),
            child: const DeviceInfoScreen(),
          );
        },
      ),
    );
  }
}