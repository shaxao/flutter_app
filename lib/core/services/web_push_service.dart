// Conditional export for web push service
export 'web_push_service_stub.dart'
    if (dart.library.html) 'web_push_service_web.dart';