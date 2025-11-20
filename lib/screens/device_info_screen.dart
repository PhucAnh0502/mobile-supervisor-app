import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gr2/blocs/device_info_bloc/device_info_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gr2/components/info_card.dart';
import 'package:gr2/services/device_info_service.dart';
import 'package:gr2/components/live_location_card.dart';
import 'package:geolocator/geolocator.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final DeviceInfoService _service = DeviceInfoService();
  StreamSubscription<Position>? _positionSub;
  Position? _latestPosition;
  String _liveLocationStatus = 'Stopped';

  void _startLiveLocation() async {
    setState(() => _liveLocationStatus = 'Starting...');
    try {
      final stream = await _service.getPositionStream(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      );

      _positionSub = stream.listen((pos) {
        setState(() {
          _latestPosition = pos;
          _liveLocationStatus = 'Running';
        });
      }, onError: (err) {
        setState(() => _liveLocationStatus = 'Error: $err');
      });
    } catch (e) {
      setState(() => _liveLocationStatus = 'Error: $e');
    }
  }

  void _stopLiveLocation() {
    _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _liveLocationStatus = 'Stopped';
      _latestPosition = null;
    });
  }

  @override
  void dispose() {
    _stopLiveLocation();
    super.dispose();
  }

  Future<void> _showCellDetails(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _service.getCellInfoList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No cell details available'),
              );
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return ListView.builder(
                  controller: scrollController,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final cell = list[index];
                    // extract common fields for nicer display
                    final lac = cell['lac'] ?? cell['tac'] ?? cell['LAC'] ?? cell['tacId'];
                    final cid = cell['cid'] ?? cell['ci'] ?? cell['CI'] ?? cell['ciId'];
                    final mcc = cell['mcc'] ?? cell['MCC'];
                    final mnc = cell['mnc'] ?? cell['MNC'];

                    // build a list of remaining entries excluding the ones we display separately
                    final excludedKeys = {'lac','tac','LAC','tacId','cid','ci','CI','ciId','mcc','MCC','mnc','MNC'};
                    final remaining = cell.entries.where((e) => !excludedKeys.contains(e.key)).toList();

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cell #${index + 1} - ${cell['type'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MCC', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(mcc?.toString() ?? '-'),
                                  ],
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MNC', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(mnc?.toString() ?? '-'),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LAC/TAC', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(lac?.toString() ?? '-'),
                                  ],
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CID/CI', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(cid?.toString() ?? '-'),
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(),
                            const SizedBox(height: 8),
                            // remaining key/value pairs
                            ...remaining.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  const SizedBox(width: 8),
                                  Expanded(flex: 5, child: Text(e.value?.toString() ?? '')),
                                ],
                              ),
                            )).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
        builder: (context, state) {
          if (state is DeviceInfoInitial) {
            return _buildInitial(context);
          }
          if (state is DeviceInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DeviceInfoLoaded) {
            return _buildLoadedView(context, state);
          }
          if (state is DeviceInfoError) {
            return _buildErrorView(context, state.message);
          }
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }

  Widget _buildInitial(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Press the button to fetch device info', style: TextStyle(fontSize: 16),),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Fetch Device Info'),
            onPressed: () {
              context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, DeviceInfoLoaded state) {

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
      },
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          InfoCard(
            icon: Icons.phone_android,
            title: 'Device Name',
            content: state.deviceName,
          ),
          InfoCard(
            icon: Icons.phone,
            title: 'Phone Number',
            content: state.phoneNumber,
          ),
          InfoCard(
            icon: Icons.location_on,
            title: 'Location',
            content: state.location,
          ),
          InfoCard(
            icon: Icons.network_cell,
            title: 'Cell Info',
            content: state.cellInfo,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await _showCellDetails(context);
              },
              icon: const Icon(Icons.details),
              label: const Text('Show cell details'),
            ),
          ),

          // Live location card (extracted to a reusable component)
          LiveLocationCard(
            position: _latestPosition,
            status: _liveLocationStatus,
            onStart: _positionSub == null ? _startLiveLocation : () {},
            onStop: _positionSub != null ? _stopLiveLocation : () {},
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
              },
              child: const Text('Refresh'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $message', style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                context.read<DeviceInfoBloc>().add(FetchDeviceInfo());
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}