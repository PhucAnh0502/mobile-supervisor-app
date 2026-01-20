import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Services & Models
import 'package:gr2/services/storage_service.dart';
import 'package:gr2/services/api_service.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/models/user_info.dart';

// State Management
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

  @override
  void dispose() {
    for (var controller in [_nameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _citizenCtrl]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final user = UserInfo(
        fullName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        citizenId: _citizenCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        device: await DeviceInfoService().getDeviceInfo(),
      );

      final success = await ApiService().registerUser(user);
      await StorageService().setHasRegistered();

      if (success && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => BlocProvider(
        create: (_) => DeviceInfoBloc(DeviceInfoService()),
        child: const DeviceInfoScreen(),
      ),
    ));
  }

  InputDecoration _inputDec({required String label, required IconData icon}) {
    final primary = Theme.of(context).primaryColor;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[700]),
      prefixIcon: Icon(icon, color: primary, size: 22), // Icon chuyển sang màu cam
      filled: true,
      fillColor: primary.withOpacity(0.04), // Nền ô nhập liệu hơi ánh cam
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  Icon(Icons.assignment_ind_rounded, size: 60, color: primary),
                  const SizedBox(height: 20),
                  Text(
                    'Hoàn tất hồ sơ',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primary),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: _inputDec(label: 'Họ và tên', icon: Icons.person_outline),
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập họ tên' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _citizenCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec(label: 'Số CCCD/CMND', icon: Icons.badge_outlined),
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập CCCD' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDec(label: 'Số điện thoại', icon: Icons.phone_android),
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập SĐT' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: _inputDec(label: 'Email', icon: Icons.mail_outline),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: _inputDec(label: 'Địa chỉ', icon: Icons.map_outlined),
                        ),
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: _submitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('ĐĂNG KÝ NGAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}