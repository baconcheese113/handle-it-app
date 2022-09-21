import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:handle_it/common/ble_provider.dart';

class FakeBluetoothCharacteristic implements BluetoothCharacteristic {
  final List<int> _fakeValue = [];
  final Guid _fakeUuid;
  bool _fakeNotify = false;
  Stream<List<int>> _fakeNotifyVal = const Stream.empty();

  FakeBluetoothCharacteristic.create(Guid uuid) : _fakeUuid = uuid;

  @override
  bool get isNotifying => _fakeNotify;

  @override
  Stream<List<int>> get onValueChangedStream => _fakeNotifyVal;

  @override
  Future<List<int>> read() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _fakeValue;
  }

  @override
  Future<bool> setNotifyValue(bool notify) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeNotifyVal =
        notify ? Stream.periodic(const Duration(milliseconds: 500), (count) => _fakeValue) : const Stream.empty();
    return _fakeNotify = notify;
  }

  @override
  Guid get uuid => _fakeUuid;

  @override
  Stream<List<int>> get value => Stream.value(_fakeValue);

  @override
  Future<Null> write(List<int> value, {bool withoutResponse = false}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return null;
  }

  @override
  DeviceIdentifier get deviceId => throw UnimplementedError();
  @override
  List<int> get lastValue => throw UnimplementedError();
  @override
  List<BluetoothDescriptor> get descriptors => throw UnimplementedError();
  @override
  CharacteristicProperties get properties => throw UnimplementedError();
  @override
  Guid? get secondaryServiceUuid => throw UnimplementedError();
  @override
  Guid get serviceUuid => throw UnimplementedError();
}

class FakeBluetoothService implements BluetoothService {
  final Guid _fakeUuid;
  final List<FakeBluetoothCharacteristic> _fakeChars;
  FakeBluetoothService.create(Guid uuid, List<FakeBluetoothCharacteristic> chars)
      : _fakeUuid = uuid,
        _fakeChars = chars;

  @override
  List<BluetoothCharacteristic> get characteristics => _fakeChars;

  @override
  Guid get uuid => _fakeUuid;

  @override
  DeviceIdentifier get deviceId => throw UnimplementedError();
  @override
  List<BluetoothService> get includedServices => throw UnimplementedError();
  @override
  bool get isPrimary => throw UnimplementedError();
}

class FakeBluetoothDevice extends BluetoothDevice {
  List<BluetoothService> _fakeServices = [];
  BluetoothDeviceState _fakeState = BluetoothDeviceState.disconnected;
  FakeBluetoothDevice.fromId(id) : super.fromId(id);

  @override
  Stream<List<BluetoothService>> get services => Stream.value(_fakeServices);

  @override
  Future<List<BluetoothService>> discoverServices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final chars = [
      FakeBluetoothCharacteristic.create(Guid(COMMAND_CHARACTERISTIC_UUID)),
      FakeBluetoothCharacteristic.create(Guid("00002a01-0000-1000-8000-00805F9B34FB")),
    ];
    final service = FakeBluetoothService.create(Guid(HUB_SERVICE_UUID), chars);
    _fakeServices = [service];
    return [service];
  }

  @override
  Future<void> connect({Duration? timeout, bool autoConnect = true}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fakeState = BluetoothDeviceState.connected;
  }

  @override
  Stream<BluetoothDeviceState> get state => Stream.value(_fakeState);

  @override
  Future disconnect() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fakeState = BluetoothDeviceState.disconnected;
  }
}
