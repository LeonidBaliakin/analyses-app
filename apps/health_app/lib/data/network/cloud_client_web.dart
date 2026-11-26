import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createCloudClient() => BrowserClient()..withCredentials = true;
const usesCloudCookies = true;
