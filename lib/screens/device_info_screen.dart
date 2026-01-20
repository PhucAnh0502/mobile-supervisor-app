import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:gr2/services/device_info_service.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> with WidgetsBindingObserver {
  Timer? _autoSendTimer;
  bool _isAutoMode = true;
  bool _useMqtt = false;
  
  final Color primaryColor = const Color(0xFFEB420F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
    if (_isAutoMode) _startAutoSend();
  }

  @override
  void dispose() {
    _stopAutoSend();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      if (_isAutoMode) WakelockPlus.enable();
      context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
    }
  }

  // --- Logic Điều khiển ---
  void _startAutoSend() {
    WakelockPlus.enable();
    _autoSendTimer?.cancel(); // Tránh tạo nhiều timer chồng nhau
    _autoSendTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _triggerSend();
    });
  }

  void _stopAutoSend() {
    _autoSendTimer?.cancel();
    WakelockPlus.disable();
  }

  void _triggerSend() {
    context.read<DeviceInfoBloc>().add(SubmitCollectedDataEvent(useMqtt: _useMqtt));
    final channel = _useMqtt ? 'MQTT' : 'API';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('Đang gửi qua $channel...'),
          ],
        ),
        backgroundColor: _useMqtt ? Colors.deepOrange : primaryColor,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- Thành phần giao diện ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildSquareCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: 28),
          const SizedBox(height: 20),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.isEmpty || value == "..." ? "N/A" : value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty || value == "..." ? "Đang cập nhật..." : value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'monospace'),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolBtn(String title, IconData icon, bool selected) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _useMqtt = (title.contains("MQTT"))),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? primaryColor : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? primaryColor : Colors.grey),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? primaryColor : Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Monitor Center", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          Row(
            children: [
              Text(_isAutoMode ? "AUTO" : "PAUSED",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isAutoMode ? Colors.green : Colors.grey)),
              Switch(
                value: _isAutoMode,
                activeColor: primaryColor,
                onChanged: (val) => setState(() {
                  _isAutoMode = val;
                  val ? _startAutoSend() : _stopAutoSend();
                }),
              ),
            ],
          )
        ],
      ),
      body: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
        builder: (context, state) {
          String deviceName = "...";
          String phoneNumber = "...";
          String location = "...";
          String cellInfo = "...";

          if (state is DeviceInfoLoaded) {
            deviceName = state.deviceName;
            phoneNumber = state.phoneNumber;
            location = state.location;
            cellInfo = state.cellInfo;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isAutoMode 
                        ? [primaryColor, const Color(0xFFFF7043)] 
                        : [const Color(0xFF757575), const Color(0xFF9E9E9E)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Truyền phát 10 giây/lần", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(_isAutoMode ? "Live Monitoring..." : "Đang tạm dừng", 
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildSectionTitle("Giao thức kết nối"),
                Row(
                  children: [
                    _buildProtocolBtn("REST API", Icons.language, !_useMqtt),
                    const SizedBox(width: 12),
                    _buildProtocolBtn("MQTT HIVE", Icons.sensors, _useMqtt),
                  ],
                ),

                _buildSectionTitle("Dữ liệu hệ thống"),
                Row(
                  children: [
                    Expanded(child: _buildSquareCard("Thiết bị", deviceName, Icons.smartphone, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSquareCard("SIM Phone", phoneNumber, Icons.sim_card, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildWideCard("Vị trí GPS", location, Icons.gps_fixed, Colors.green),
                _buildWideCard("Trạm phát (Cell)", cellInfo, Icons.radar, Colors.purple),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _triggerSend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("GỬI DỮ LIỆU THỦ CÔNG", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                
                Center(
                  child: TextButton(
                    onPressed: () => _showCellListModal(context),
                    child: Text("Xem danh sách Cell đầy đủ", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Modal hiển thị Cell ---
  void _showCellListModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text("Live Cell Tower Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: DeviceInfoService().getCellInfoList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const Center(child: Text('Không tìm thấy dữ liệu trạm phát'));

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final cell = list[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cell_tower, color: primaryColor),
                                const SizedBox(width: 12),
                                Expanded(child: Text('${cell['type'] ?? 'Cell'}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                Text('${cell['rssi'] ?? cell['dbm'] ?? ''} dBm'),
                              ],
                            ),
                            const Divider(),
                            Wrap(
                              spacing: 8,
                              children: [
                                _cellMetaChip('CID', (cell['cid'] ?? cell['ci'] ?? '').toString()),
                                _cellMetaChip('LAC', (cell['lac'] ?? cell['tac'] ?? '').toString()),
                                _cellMetaChip('PCI', (cell['pci'] ?? '').toString()),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _cellMetaChip(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.grey[100],
      visualDensity: VisualDensity.compact,
    );
  }
}