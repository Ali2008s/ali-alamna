/// This file uses conditional imports to provide the correct
/// HttpOverrides implementation per platform.
export 'http_overrides_native.dart'
    if (dart.library.html) 'http_overrides_stub.dart';
