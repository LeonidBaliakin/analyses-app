// Debug-only entry point for checking real app navigation and process restarts.
// No fake gateways, storage, permissions or coordinates are injected.
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:health_app/app/shell/app_shell.dart';
import 'package:health_app/features/device_access/device_access.dart';
import 'package:health_app/main.dart' as app;

Future<void> main() async {
  enableFlutterDriverExtension(handler: (_) async => _locationState());
  await app.main();
}

String _locationState() {
  DeviceAccessViewModel? model;
  String? route;
  void visit(Element element) {
    if (element.widget case DeviceAccessScope(model: final found)) {
      model = found;
    }
    if (element.widget is AppShell) {
      route = GoRouter.of(element).routeInformationProvider.value.uri.path;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
  return jsonEncode({
    'confirmed': model?.locationConfirmed,
    'currentAddress': model?.location?.address,
    'lastAddress': model?.lastLocation?.address,
    'candidateAddress': model?.pendingLocation?.address,
    'busy': model?.isBusy,
    'issue': model?.locationIssue?.name,
    'route': route,
  });
}
