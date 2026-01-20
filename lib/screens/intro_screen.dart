import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gr2/screens/registration_screen.dart';
import 'package:gr2/services/storage_service.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:gr2/screens/device_info_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scale = CurvedAnimation(parent: _ctl, curve: Curves.easeOutBack);
    _ctl.forward();

    Future.delayed(const Duration(milliseconds: 3200), () async {
      if (!mounted) return;
      final isFirst = await StorageService().isFirstLaunch();
      if (!mounted) return;
      if (isFirst) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (ctx, a1, a2) => const RegistrationScreen(),
          transitionsBuilder: (ctx, anim, a2, child) => FadeTransition(opacity: anim, child: child),
        ));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => BlocProvider(create: (_) => DeviceInfoBloc(DeviceInfoService()), child: const DeviceInfoScreen())));
      }
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Widget _illustration(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Vòng tròn nền cam nhạt
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
        ),
        // Icon điện thoại chính
        Transform.translate(
          offset: const Offset(-30, -10),
          child: Container(
            width: 160,
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withOpacity(0.3), width: 2),
              boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 20)],
            ),
            child: Icon(Icons.phone_iphone, size: 80, color: primary),
          ),
        ),
        // Icon bản đồ nhỏ hơn
        Transform.translate(
          offset: const Offset(50, 40),
          child: Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              color: primary, // Màu cam đặc
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: const Icon(Icons.map_rounded, size: 48, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.white, // Chuyển sang trắng để màu cam nổi bật nhất
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(scale: _scale, child: _illustration(context)),
              const SizedBox(height: 40),
              Text(
                'Chào mừng',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: primary, // Tiêu đề màu cam
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Ứng dụng đang chuyển sang phần hoàn tất hồ sơ cá nhân của bạn...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}