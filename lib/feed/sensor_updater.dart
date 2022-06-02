import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

const String SPOTA_SERVICE_UUID = "0000fef5-0000-1000-8000-00805f9b34fb";
const String VOLTS_SERVICE_UUID = "1000181a-0000-1000-8000-00805f9b34fb";
const String SPOTA_MEM_DEV_UUID = "8082caa8-41a6-4021-91c6-56f9b954cc34";
const String SPOTA_GPIO_MAP_UUID = "724249f0-5eC3-4b5f-8804-42345af08651";
// const String SPOTA_MEM_INFO_UUID = "6c53db25-47a1-45fe-a022-7c92fb334fd4";
const String SPOTA_PATCH_LEN_UUID = "9d84b9a3-000c-49d8-9183-855b673fda31";
const String SPOTA_PATCH_DATA_UUID = "457871e8-d516-4ca1-9116-57d0b17b9cb2";
const String SPOTA_SERV_STATUS_UUID = "5f78df94-798c-46f5-990a-b3eb6a065c88";

const String ORG_BLUETOOTH_SERVICE_DEVICE_INFORMATION = "0000180a-0000-1000-8000-00805f9b34fb";
// const String ORG_BLUETOOTH_CHARACTERISTIC_MANUFACTURER_NAME_STRING = "00002A29-0000-1000-8000-00805f9b34fb";
// const String ORG_BLUETOOTH_CHARACTERISTIC_MODEL_NUMBER_STRING = "00002A24-0000-1000-8000-00805f9b34fb";
// const String ORG_BLUETOOTH_CHARACTERISTIC_SERIAL_NUMBER_STRING = "00002A25-0000-1000-8000-00805f9b34fb";
// const String ORG_BLUETOOTH_CHARACTERISTIC_HARDWARE_REVISION_STRING = "00002A27-0000-1000-8000-00805f9b34fb";
// const String ORG_BLUETOOTH_CHARACTERISTIC_FIRMWARE_REVISION_STRING = "00002A26-0000-1000-8000-00805f9b34fb";
const String ORG_BLUETOOTH_CHARACTERISTIC_SOFTWARE_REVISION_STRING = "00002A28-0000-1000-8000-00805f9b34fb";

class SensorUpdater extends StatefulWidget {
  const SensorUpdater({Key? key, required this.latestVersion}) : super(key: key);

  final Version latestVersion;

  @override
  State<SensorUpdater> createState() => _SensorUpdaterState();
}

class _SensorUpdaterState extends State<SensorUpdater> {
  bool _scanning = false;
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? _foundSensor;
  BluetoothDeviceState _deviceState = BluetoothDeviceState.disconnected;
  StreamSubscription<BluetoothDeviceState>? _stateStreamSub;
  double _progressPercent = -1;
  Version? _sensorVersion;
  final List<int> _firmwareBin = [];
  int? _rssi;
  bool _connectEnabled = false;

  void autoConnect() async {
    await _flutterBlue.stopScan();
    setState(() => _scanning = true);
    print("bluetooth state is now POWERED_ON, starting sensor scan");
    await for (final r
        in _flutterBlue.scan(withServices: [Guid(VOLTS_SERVICE_UUID)], timeout: const Duration(seconds: 10))) {
      print("Scanned sensor ${r.device.name}, RSSI ${r.rssi}");
      _flutterBlue.stopScan();
      setState(() => _foundSensor = r.device);
      break;
    }
    if (mounted) setState(() => _scanning = false);
    if (_foundSensor == null) {
      print("no devices found and scan stopped");
      return;
    }

    _stateStreamSub = _foundSensor!.state.listen((state) {
      setState(() => _deviceState = state);
      print(">>> New sensor connection state is: $state");
    });

    print(">>> sensor connecting");
    await _foundSensor!.connect();
    print(">>> sensor connecting finished");

    final services = await _foundSensor!.discoverServices();
    final deviceInfoService = services.firstWhere((s) => s.uuid == Guid(ORG_BLUETOOTH_SERVICE_DEVICE_INFORMATION));
    final softwareVerChar = deviceInfoService.characteristics
        .firstWhere((c) => c.uuid == Guid(ORG_BLUETOOTH_CHARACTERISTIC_SOFTWARE_REVISION_STRING));
    List<int> softwareBytes = await softwareVerChar.read();
    final sensorVersionStr = utf8.decode(softwareBytes).replaceAll(RegExp(r'\x00'), "");
    print(">>> sensor software version string: $sensorVersionStr");
    final sensorVersion = Version.parse(sensorVersionStr);
    print(">>> parsed to $sensorVersion");
    final rssi = await _foundSensor!.readRssi();
    setState(() {
      _sensorVersion = sensorVersion;
      _rssi = rssi;
    });

    print(">>> requestingMtu of length 244");
    final mtuStream = _foundSensor!.mtu.listen((newMtu) {
      print(">>> new MTU is $newMtu");
    });
    // not sure why mtu needs to be 3 bytes longer, but it's in example
    await _foundSensor!.requestMtu(244 + 3);
    await Future.delayed(const Duration(milliseconds: 100));
    mtuStream.cancel();
  }

  void downloadUpdate() async {
    final verStr = "${widget.latestVersion.major}-${widget.latestVersion.minor}-${widget.latestVersion.patch}";
    final req = await http.Client()
        .send(http.Request('GET', Uri.parse("${dotenv.env['FIRMWARE_SERVER_URL']}/sensor-$verStr.img")));
    int total = req.contentLength ?? 0;
    print(">>> ContentLength is $total");
    req.stream.listen((newBytes) {
      _firmwareBin.addAll(newBytes);
      int received = _firmwareBin.length;
      print('>>> newBytes length is ${newBytes.length} and we\'ve received $received so far');
      setState(() => _progressPercent = received / total);
    }).onDone(() {
      int crc = _firmwareBin.reduce((crcCode, byte) => crcCode ^= byte) & 0xff;
      _firmwareBin.add(crc);
      print('>>> stream complete, crc appended is 0x${crc.toRadixString(16)}');
      setState(() => _progressPercent = -1);
    });
  }

  // STEP 0
  // Request MTU 3 bytes longer than blockSize (244 + 3 | 0x00f4 + 3 = 0x00f7)
  // Append 1 byte CRC to end of firmware file. Create it by XOR'ing each byte together (crcCode ^= nextByte)
  // STEP 1
  // (optional) Request high connection priority
  // Register SPOTA_SERV_STATUS notifications on (value meanings in suotar.h and BluetoothManager.initErrorMap())
  // STEP 2
  // Write SPOTA_MEM_DEV = "External SPI" (0x13000000)
  // Read IMG_STARTED (0x10) from SPOTA_SERV_STATUS
  // STEP 3
  // Write SPOTA_GPIO_MAP to 0x03000104 (MOSI, MISO, CS, CLK)
  // STEP 4
  // Write SPOTA_PATCH_LEN to current block size (244 | 0x00f4)
  // STEP 5 (repeated)
  // Write next block to SPOTA_PATCH_DATA (if block size changes, update SPOTA_PATCH_LEN first)
  // Listen for SPOTA_SERV_STATUS notification of SUOTAR_CMP_OK (0x02)
  // When finished...
  // Write END_SIGNAL (0xfe000000) to SPOTA_MEM_DEV
  // (optional) Request decreased priority
  // Write REBOOT_SIGNAL (0xfd000000) to SPOTA_MEM_DEV
  void installUpdate(void Function({String? errorMsg}) onEnd) async {
    if (_foundSensor == null || _firmwareBin.isEmpty) return;

    const blockSize = 244;
    final totalBlocks = (_firmwareBin.length / blockSize).ceil();

    setState(() => _progressPercent = 0);
    print(">>> discoveringservices");
    final services = await _foundSensor!.discoverServices();

    final suotaService = services.firstWhere((s) => s.uuid == Guid(SPOTA_SERVICE_UUID));
    final servStatusChar = suotaService.characteristics.firstWhere((c) => c.uuid == Guid(SPOTA_SERV_STATUS_UUID));
    final memDevChar = suotaService.characteristics.firstWhere((c) => c.uuid == Guid(SPOTA_MEM_DEV_UUID));
    final gpioMapChar = suotaService.characteristics.firstWhere((c) => c.uuid == Guid(SPOTA_GPIO_MAP_UUID));
    final patchLenChar = suotaService.characteristics.firstWhere((c) => c.uuid == Guid(SPOTA_PATCH_LEN_UUID));
    final patchDataChar = suotaService.characteristics.firstWhere((c) => c.uuid == Guid(SPOTA_PATCH_DATA_UUID));
    print(">>> Finished finding chars");

    await servStatusChar.setNotifyValue(true);
    print(">>> setNotifyValue to true");
    int servStatus = -1;
    final servStatusStream = servStatusChar.onValueChangedStream.listen((value) {
      print(">>> SERV_STATUS new value: 0x${value[0].toRadixString(16)}");
      servStatus = value[0];
    });

    print(">>> Writing SPOTA_MEM_DEV = 'External SPI' (0x13000000)");
    await memDevChar.write([0x00, 0x00, 0x00, 0x13]);

    // Wait for IMG_STARTED (0x10) from SPOTA_SERV_STATUS
    while (servStatus == -1) {
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (servStatus != 0x10) {
      servStatusStream.cancel();
      onEnd(errorMsg: "Error: Received 0x${servStatus.toRadixString(16)} while starting");
      return;
    }
    servStatus = -1;

    await Future.delayed(const Duration(milliseconds: 200));

    print(">>> Writing SPOTA_GPIO_MAP = 0x03000104");
    await gpioMapChar.write([0x04, 0x01, 0x00, 0x03]);

    print(">>> Writing SPOTA_PATCH_LEN = 244");
    await patchLenChar.write([0xf4, 0x00]);

    int lastBlockSize = _firmwareBin.length % blockSize;
    if (lastBlockSize == 0) lastBlockSize = blockSize;
    int currentBlock = 0;
    while (currentBlock < totalBlocks && _deviceState == BluetoothDeviceState.connected) {
      if (servStatus > 2) break;
      if (currentBlock > 0 && servStatus != 0x02) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }
      if (currentBlock == totalBlocks - 1) {
        //  If last block....
        print(">>> Changing blockSize to $lastBlockSize");
        await patchLenChar.write([lastBlockSize, 0x00]);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final currentPos = currentBlock * blockSize;
      final currentEnd = min(currentPos + blockSize, _firmwareBin.length);
      final bytesToWrite = _firmwareBin.getRange(currentPos, currentEnd).toList();
      print("Writing block ${currentBlock + 1} of $totalBlocks. Block size is ${bytesToWrite.length}");
      await patchDataChar.write(bytesToWrite, withoutResponse: true);
      currentBlock++;
      servStatus = -1;
      setState(() => _progressPercent = currentBlock / totalBlocks);
    }

    if (currentBlock < totalBlocks) {
      setState(() => _progressPercent = -1);
      servStatusStream.cancel();
      print(">>> transfer timed out");
      onEnd(errorMsg: "Error: Received 0x${servStatus.toRadixString(16)} while transferring");
      return;
    }

    // Listen for SPOTA_SERV_STATUS notification of SUOTAR_CMP_OK (0x02)
    while (servStatus == -1) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    servStatus = -1;
    print(">>> Writing END_SIGNAL (0xfe000000) to SPOTA_MEM_DEV");
    await memDevChar.write([0x00, 0x00, 0x00, 0xfe]);

    while (servStatus == -1) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    servStatus = -1;

    onEnd();
    print(">>> Update Successful!");

    print(">>> Writing RESET_SIGNAL (0xfd000000) to SPOTA_MEM_DEV");
    try {
      memDevChar.write([0x00, 0x00, 0x00, 0xfd]);
    } catch (err) {
      print(">>> Error writing RESET_SIGNAL $err");
    } finally {
      resetState(true);
    }
  }

  @override
  void initState() {
    if (_connectEnabled) autoConnect();
    super.initState();
  }

  void resetState(bool updateState) {
    _foundSensor?.disconnect();
    _flutterBlue.stopScan();
    _stateStreamSub?.cancel();
    _firmwareBin.clear();
    if (!updateState) return;
    setState(() {
      _progressPercent = -1;
      _foundSensor = null;
      _sensorVersion = null;
      _deviceState = BluetoothDeviceState.disconnected;
      _scanning = false;
    });
  }

  @override
  void dispose() {
    resetState(false);
    super.dispose();
  }

  void handleSwitch(bool isNowEnabled) {
    if (isNowEnabled) {
      autoConnect();
    } else {
      resetState(true);
    }
    setState(() => _connectEnabled = !_connectEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _deviceState == BluetoothDeviceState.connected;
    final bluetoothIconColor = () {
      if (!_scanning && _foundSensor == null) return Colors.grey;
      if (isConnected) return Colors.green;
      return Colors.amber;
    }();

    final sensorTitle = () {
      if (_foundSensor == null) return "No sensor found...";
      return "Sensor ${_foundSensor!.name}";
    }();

    onInstallEnd({String? errorMsg}) {
      if (!mounted) return;
      final msg = errorMsg ?? "Update successful!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Widget getActionWidget() {
      if (_sensorVersion == widget.latestVersion) {
        return const Padding(padding: EdgeInsets.only(bottom: 20), child: Text("No updates available"));
      }
      if (_sensorVersion != null && _sensorVersion! < widget.latestVersion && _firmwareBin.isEmpty) {
        return TextButton(
            onPressed: downloadUpdate, child: Text("Download Firmware v${widget.latestVersion.toString()}"));
      }
      if (_progressPercent > -1) {
        return LinearProgressIndicator(value: _progressPercent);
      }
      if (_firmwareBin.isNotEmpty && _progressPercent == -1) {
        return TextButton(
            onPressed: () => installUpdate(onInstallEnd), child: Text("Install v${widget.latestVersion.toString()}"));
      }
      return const SizedBox();
    }

    return Column(
      children: [
        Row(children: [
          Switch(value: _connectEnabled, onChanged: _progressPercent == -1 ? handleSwitch : null),
          const Text("Connect to Sensors to check for updates"),
        ]),
        if (_connectEnabled)
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.bluetooth, color: bluetoothIconColor),
                  title: Text(sensorTitle),
                  subtitle: isConnected && _sensorVersion != null
                      ? Text("RSSI $_rssi | Firmware v${_sensorVersion.toString()}")
                      : null,
                ),
                getActionWidget(),
              ],
            ),
          ),
      ],
    );
  }
}
