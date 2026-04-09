import 'dart:io';

class AllowHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return HttpClient();
  }
}
