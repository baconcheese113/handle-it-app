import 'dart:io';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/common/ble_provider.dart';

import 'fake_flutter_blue.dart';

String generateRandomMacAddress() {
  final r = Random();
  return List.generate(6, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join(":");
}

const TEST_HUB_UUID = "12341234123412341234";
final TEST_HUB_MAC = generateRandomMacAddress();
final TEST_SENSOR_MAC = generateRandomMacAddress();

class FakeBleProvider extends BleProvider {
  @override
  Future<BluetoothDevice?> tryGetConnectedDevice(String name) {
    return Future(() => null);
  }

  @override
  Future<bool> tryTurnOnBle() {
    return Future(() => true);
  }

  @override
  Future<BluetoothDevice?> scan({
    required bool Function(BluetoothDevice p1, String? iosMac) onScanResult,
    List<Guid> services = const [],
    Duration? timeout = const Duration(seconds: 20),
  }) async {
    scanning = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    final mac = Platform.isIOS ? TEST_HUB_UUID : TEST_HUB_MAC;
    final mockBluetoothDevice = FakeBluetoothDevice.fromId(TEST_HUB_MAC);
    onScanResult(mockBluetoothDevice, TEST_HUB_MAC);
    await Future.delayed(const Duration(milliseconds: 200));
    scanning = false;
    notifyListeners();
    return mockBluetoothDevice;
  }

  @override
  Future<void> stopScan() async {
    await Future.delayed(const Duration(milliseconds: 200));
    scanning = false;
    notifyListeners();
  }
}
