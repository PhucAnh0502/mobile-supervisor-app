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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Lấy dữ liệu lần đầu để hiển thị lên màn hình
    context.read<DeviceInfoBloc>().add(FetchDeviceInfo());

    if (_isAutoMode) {
      _startAutoSend();
    }
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
      print("App ẩn: Background Mode (Chỉ GPS hoạt động tốt)");
    } else if (state == AppLifecycleState.resumed) {
      if (_isAutoMode) WakelockPlus.enable();
      context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
      print("App hiện: Foreground Mode (Full Data)");
    }
  }

  void _startAutoSend() {
    WakelockPlus.enable();

    _autoSendTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      context.read<DeviceInfoBloc>().add(SubmitCollectedDataEvent());
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Auto: Đang gửi dữ liệu..."),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _stopAutoSend() {
    _autoSendTimer?.cancel();
    WakelockPlus.disable();
  }

  void _showCellListModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Danh sách Cell (Live Fetch)", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<String>(
                    future: DeviceInfoService().getCellInfo(), 
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("Không có dữ liệu Cell"));
                      }
                      
                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          snapshot.data!, 
                          style: const TextStyle(fontFamily: 'Courier'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(content.isEmpty ? "N/A" : content),
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Monitor"),
        actions: [
          Switch(
            value: _isAutoMode,
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() {
                _isAutoMode = val;
                if (_isAutoMode) {
                  _startAutoSend();
                } else {
                  _stopAutoSend();
                }
              });
            },
          )
        ],
      ),
      body: BlocConsumer<DeviceInfoBloc, DeviceInfoState>(
        listener: (context, state) {
          if (state is DeviceInfoSubmitSuccess) {
          } else if (state is DeviceInfoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
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

          return Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: _isAutoMode ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _isAutoMode ? Colors.green : Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isAutoMode ? Icons.autorenew : Icons.pause, 
                           color: _isAutoMode ? Colors.green : Colors.grey),
                      const SizedBox(width: 10),
                      Text(
                        _isAutoMode 
                        ? "AUTO MODE: ON (Giữ màn sáng)" 
                        : "AUTO MODE: OFF",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isAutoMode ? Colors.green : Colors.grey
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),

                Expanded(
                  child: state is DeviceInfoLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildInfoCard("Thiết bị", deviceName, Icons.phone_android),
                              _buildInfoCard("Số điện thoại", phoneNumber, Icons.sim_card),
                              _buildInfoCard("Vị trí GPS", location, Icons.location_on),
                              _buildInfoCard("Cell Info (Gần nhất)", cellInfo, Icons.signal_cellular_alt),
                              
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCellListModal(context),
                                  icon: const Icon(Icons.list_alt),
                                  label: const Text("Xem danh sách Cell (Fetch Live)"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: const BorderSide(color: Colors.blue),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<DeviceInfoBloc>().add(SubmitCollectedDataEvent());
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text("Gửi thủ công ngay"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20), 
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}