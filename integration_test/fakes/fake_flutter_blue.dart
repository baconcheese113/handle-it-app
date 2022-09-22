import 'dart:convert';
import 'dart:math';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:graphql/client.dart';
import 'package:handle_it/common/ble_provider.dart';

import '../utils.dart';
import 'fake_ble_provider.dart';

Future<String> createHub(GraphQLClient client, int userId) async {
  final r = Random();
  final imei = List.generate(18, (index) => r.nextInt(11)).join();
  final res = await client.mutate(MutationOptions(document: gql('''
    mutation LoginAsHubMutation {
      loginAsHub(imei: "$imei", serial: "$TEST_HUB_MAC", userId: $userId)
    }
  ''')));
  print("createHub response is ${res.data}");
  return res.data!["loginAsHub"];
}

Future<int> getHubId(GraphQLClient client) async {
  final res = await client.query(QueryOptions(document: gql('''
    query getHubViewer {
      hubViewer {
        id
      }
    }
  ''')));
  print("hubViewer response is ${res.data}");
  return res.data!["hubViewer"]["id"];
}

class FakeBluetoothCharacteristic implements BluetoothCharacteristic {
  List<int> _fakeValue = [];
  final Guid _fakeUuid;
  bool _fakeNotify = false;
  Stream<List<int>> _fakeNotifyVal = const Stream.empty();
  GraphQLClient _client;

  FakeBluetoothCharacteristic.create(Guid uuid, GraphQLClient client)
      : _client = client,
        _fakeUuid = uuid;

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
    await Future.delayed(const Duration(milliseconds: 500));
    final strVal = String.fromCharCodes(value);
    if (strVal.startsWith("UserId:")) {
      final userId = int.parse(strVal.substring(7));
      final token = await createHub(_client, userId);
      _client = getClient(token: token);
      final hubId = await getHubId(_client);
      _fakeValue = utf8.encode("HubId:$hubId");
    } else if (strVal == "StartSensorSearch:1") {
      _fakeValue = utf8.encode("SensorFound:$TEST_SENSOR_MAC");
    } else if (strVal == "SensorConnect:1") {
      _fakeValue = utf8.encode("SensorAdded:1");
    }
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
  GraphQLClient _client;
  FakeBluetoothDevice.fromId(id)
      : _client = getClient(),
        super.fromId(id);

  @override
  Stream<List<BluetoothService>> get services => Stream.value(_fakeServices);

  @override
  Future<List<BluetoothService>> discoverServices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final chars = [
      FakeBluetoothCharacteristic.create(Guid(COMMAND_CHARACTERISTIC_UUID), _client),
      FakeBluetoothCharacteristic.create(Guid("00002a01-0000-1000-8000-00805F9B34FB"), _client),
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

  @override
  String get name => HUB_NAME;
}
