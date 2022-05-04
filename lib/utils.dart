import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gql/ast.dart';
import 'package:permission_handler/permission_handler.dart';

DocumentNode addFragments(DocumentNode doc, List<DocumentNode> fragments) {
  print("doc is ${doc.definitions.length}");
  final newDefinitions = Set<DefinitionNode>.from(doc.definitions);
  for (final frag in fragments) {
    newDefinitions.addAll(frag.definitions);
  }
  return DocumentNode(definitions: newDefinitions.toList(), span: doc.span);
}

Future<bool> requestPermission(Permission perm) async {
  PermissionStatus status = await perm.status;
  print("Current status for ${perm.toString()} is $status");
  if (!status.isGranted) {
    print("${perm.toString()} was not granted");
    if (!await perm.request().isGranted) {
      print("Andddd, they denied me again!");
      return false;
    }
  }
  return true;
}

Future<bool> tryPowerOnBLE() async {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  print("about to turn on bluetooth");
  if (!await flutterBlue.isOn) {
    bool isNowOn = await flutterBlue.turnOn();
    if (!isNowOn) {
      print("Unable to turn on bluetooth");
      return false;
    }
  }
  return true;
}
