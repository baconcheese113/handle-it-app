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
  final _flutterBlue = FlutterBluePlus.instance;
  bool scanning = false;
  bool _hasPermissions = false;
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

  Future<void> _checkBlePermissions() async {
    if (Platform.isAndroid) {
      if (!await hasPermission(Permission.location) ||
          !await hasPermission(Permission.bluetoothScan) ||
          !await hasPermission(Permission.bluetoothConnect)) {
        _hasPermissions = false;
        notifyListeners();
        return;
      }
    }
    _hasPermissions = true;
    notifyListeners();
  }

  Future<bool> _requestBlePermissions() async {
    if (Platform.isAndroid) {
      if (!await requestPermission(Permission.location) ||
          !await requestPermission(Permission.bluetoothScan) ||
          !await requestPermission(Permission.bluetoothConnect)) {
        _hasPermissions = false;
        notifyListeners();
        return false;
      }
    }
    _hasPermissions = true;
    notifyListeners();
    return true;
  }

  /// Returns true if Ble turned on and permissions granted
  Future<bool> tryTurnOnBle() async {
    if (!await _requestBlePermissions()) return false;
    if (!await _flutterBlue.isOn) {
      print("about to turn on bluetooth");
      bool isNowOn = await _flutterBlue.turnOn();
      if (!isNowOn) {
        print("Unable to turn on bluetooth");
        return false;
      }
    }
    return true;
  }

  Future<BluetoothDevice?> tryGetConnectedDevice(String name) async {
    return (await _flutterBlue.connectedDevices).firstWhereOrNull((d) => d.name == name);
  }

  Future<BluetoothDevice?> scan({
    required bool Function(BluetoothDevice) onScanResult,
    List<Guid> services = const [],
    Duration? timeout = const Duration(seconds: 20),
  }) async {
    if (scanning) await stopScan();
    scanning = true;
    notifyListeners();
    BluetoothDevice? ret;
    await for (final r in _flutterBlue.scan(timeout: timeout, withServices: services)) {
      if (onScanResult(r.device)) {
        ret = r.device;
        break;
      }
    }
    await _flutterBlue.stopScan();
    scanning = false;
    notifyListeners();
    return ret;
  }

  Future<void> stopScan() async {
    await _flutterBlue.stopScan();
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
