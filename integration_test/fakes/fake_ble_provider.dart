import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/common/ble_provider.dart';

import 'fake_flutter_blue.dart';

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
    required bool Function(BluetoothDevice p1) onScanResult,
    List<Guid> services = const [],
    Duration? timeout = const Duration(seconds: 20),
  }) async {
    scanning = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    final mockBluetoothDevice = FakeBluetoothDevice.fromId("TE:ST:AD:DR:ES");
    onScanResult(mockBluetoothDevice);
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
