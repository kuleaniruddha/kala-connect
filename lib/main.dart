import 'package:flutter/material.dart';

import 'app/kala_connect_app.dart';
import 'core/firebase_bootstrap.dart';

/// The entry point intentionally stays light: intensive model work starts only
/// after the first rendered frame in the scanner screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep local demo authentication on until Firebase Phone Authentication is
  // configured in the console. It accepts OTP 123456 and persists its session.
  // Live Firebase connection enabled by default.
  const useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);
  final firebaseReady = useFirebase && await FirebaseBootstrap.initialize();
  debugPrint('🔥 Firebase initialization status: $firebaseReady');
  runApp(KalaConnectApp(firebaseReady: firebaseReady));
}
