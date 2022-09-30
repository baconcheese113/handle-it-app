import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/utils.dart';
import 'package:permission_handler/permission_handler.dart';

const String HUB_NAME = "HandleIt Hub";
const String HUB_SERVICE_UUID = "0000181a-0000-1000-8000-00805f9b34fc";
const String COMMAND_CHARACTERISTIC_UUID = "00002A58-0000-1000-8000-00805f9b34fd";
const String FIRMWARE_CHARACTERISTIC_UUID = "00002A26-0000-1000-8000-00805f9b34fb";

const String SMP_SERVICE_UUID = "8d53dc1d-1db7-4cd3-868b-8a527460aa84";
const String SMP_UPDATE_CHARACTERISTIC_UUID = "da2e7828-fbce-4e01-ae9e-261174997c48";

class BleProvider extends ChangeNotifier {
  bool scanning = false;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  Future<bool> hasBlePermissions() async {
    if (Platform.isAndroid) {
      if (!await hasPermission(Permission.location) ||
          !await hasPermission(Permission.bluetoothScan) ||
          !await hasPermission(Permission.bluetoothConnect)) {
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }

  Future<bool> _requestBlePermissions() async {
    if (Platform.isAndroid) {
      if (!await requestPermission(Permission.location) ||
          !await requestPermission(Permission.bluetoothScan) ||
          !await requestPermission(Permission.bluetoothConnect)) {
        notifyListeners();
        return false;
      }
    }
    notifyListeners();
    return true;
  }

  /// Returns true if Ble turned on and permissions granted
  Future<bool> tryTurnOnBle() async {
    if (!await _requestBlePermissions()) return false;
    if (!await FlutterBluePlus.instance.isOn) {
      print("about to turn on bluetooth");
      bool isNowOn = await FlutterBluePlus.instance.turnOn();
      if (!isNowOn) {
        print("Unable to turn on bluetooth");
        return false;
      }
    }
    return true;
  }

  Future<BluetoothDevice?> tryGetConnectedDevice(String name) async {
    return (await FlutterBluePlus.instance.connectedDevices).firstWhereOrNull((d) => d.name == name);
  }

  Future<bool> tryConnect(BluetoothDevice? hub) async {
    if (!await FlutterBluePlus.instance.isOn) return false;
    // Needed for older devices
    BluetoothDeviceState? state;
    final stateListener = hub?.state.listen((newState) {
      print("New state is $newState");
      state = newState;
    });
    await hub?.connect(timeout: const Duration(seconds: 10));
    state ??= await Future<BluetoothDeviceState?>.value(hub?.state.last).timeout(const Duration(seconds: 1));
    stateListener?.cancel();
    final isConnected = hub != null && state == BluetoothDeviceState.connected;
    return isConnected;
  }

  Future<BluetoothDevice?> scan({
    required bool Function(BluetoothDevice, String?) onScanResult,
    List<Guid> services = const [],
    Duration? timeout = const Duration(seconds: 20),
  }) async {
    if (!await FlutterBluePlus.instance.isOn) return null;
    if (scanning) await stopScan();
    scanning = true;
    notifyListeners();
    BluetoothDevice? ret;
    await for (final r in FlutterBluePlus.instance.scan(timeout: timeout, withServices: services)) {
      final advMacRaw = r.advertisementData.manufacturerData[0];
      final advMacStr = advMacRaw != null
          ? List.generate(6, (idx) => advMacRaw[idx].toRadixString(16).padLeft(2, '0')).join(":")
          : null;
      if (onScanResult(r.device, advMacStr)) {
        ret = r.device;
        break;
      }
    }
    await FlutterBluePlus.instance.stopScan();
    scanning = false;
    notifyListeners();
    return ret;
  }

  Future<void> stopScan() async {
    if (!await FlutterBluePlus.instance.isOn) return;
    await FlutterBluePlus.instance.stopScan();
    scanning = false;
    notifyListeners();
  }

  Future<BluetoothCharacteristic?> getChar(
    BluetoothDevice d,
    String serviceUuid,
    String charUuid,
  ) async {
    final existingServices = await d.services.first;
    final services = existingServices.isNotEmpty ? existingServices : await d.discoverServices();
    final service = services.firstWhereOrNull((s) => s.uuid == Guid(serviceUuid));
    final char = service?.characteristics.firstWhereOrNull((c) => c.uuid == Guid(charUuid));
    return char;
  }
}
