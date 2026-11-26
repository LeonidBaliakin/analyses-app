import 'package:provider_connector/provider_connector.dart';
import 'package:provider_connector/src/worker.dart';

Future<void> main(List<String> args) =>
    runConnector(SovaParser(), 'https://voronezh.sovamed.ru', args);
