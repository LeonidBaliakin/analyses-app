/// Development builds use the local directory alongside the existing local
/// cloud stack. Release builds require an explicitly configured public URL.
Uri? directoryEndpoint({
  required String configuredUrl,
  required bool development,
  required bool web,
  required bool android,
  required Uri page,
}) {
  if (configuredUrl.trim().isNotEmpty) {
    final value = configuredUrl.trim();
    return Uri.parse(value.endsWith('/') ? value : '$value/');
  }
  if (!development) return null;
  if (web) {
    if (!['localhost', '127.0.0.1'].contains(page.host)) return null;
    return Uri(scheme: 'http', host: page.host, port: 18086, path: '/');
  }
  return Uri.parse(
    android ? 'http://10.0.2.2:18086/' : 'http://127.0.0.1:18086/',
  );
}
