import 'package:flutter/material.dart';
import 'package:gr2/services/storage_service.dart';
import 'package:gr2/services/api_service.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/models/user_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:gr2/screens/device_info_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _citizenCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      // build UserInfo from the form
      final fullName = _nameCtrl.text.trim();
      final email = _emailCtrl.text.trim();
      final address = _addressCtrl.text.trim();
      final citizenId = _citizenCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      // fetch basic device info to include in the payload
      final device = await DeviceInfoService().getDeviceInfo();

      final user = UserInfo(
        fullName: fullName,
        address: address,
        email: email,
        citizenId: citizenId,
        phoneNumber: phone,
        device: device,
      );

      // Print payload to console
      print('Register payload: ${user.toJson()}');

      // Call API
      final api = ApiService();
      final success = await api.registerUser(user);

      await StorageService().setHasRegistered();

      if (success) {
        print('API POST success: user registered');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        print('API POST failed (registerUser returned false)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi đăng ký')), 
          );
        }
      }
    } catch (e, st) {
      print('Error while registering user: $e');
      print(st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose(); 
    _citizenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chào mừng — Hoàn tất hồ sơ'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Họ và Tên',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập họ tên'
                      : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    final emailReg = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                    return emailReg.hasMatch(v)
                        ? null
                        : 'Vui lòng nhập email hợp lệ';
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  keyboardType: TextInputType.streetAddress,
                  decoration: const InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _citizenCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Số CCCD',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập số CCCD'
                      : null,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Hoàn tất đăng ký'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    // mark registered and navigate to DeviceInfoScreen with its Bloc
                    await StorageService().setHasRegistered();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (ctx) => BlocProvider(
                              create: (_) => DeviceInfoBloc(DeviceInfoService()),
                              child: const DeviceInfoScreen(),
                            )));
                  },
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}