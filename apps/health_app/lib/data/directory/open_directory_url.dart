import 'package:url_launcher/url_launcher.dart';

Future<bool> openDirectoryUrl(Uri uri) => launchUrl(
  uri,
  mode: LaunchMode.externalApplication,
  webOnlyWindowName: '_blank',
);
