import 'package:provider_connector/provider_connector.dart';
import 'package:provider_connector/src/worker.dart';

Future<void> main(List<String> args) =>
    runConnector(SmclinicParser(), 'https://www.smclinic-spb.ru', args);
