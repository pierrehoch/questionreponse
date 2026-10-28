import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:question_reponse/core/config/app_environment.dart';

sealed class FirebaseBootstrapResult {
  const FirebaseBootstrapResult();
}

final class FirebaseBootstrapReady extends FirebaseBootstrapResult {
  const FirebaseBootstrapReady();
}

final class FirebaseBootstrapFailure extends FirebaseBootstrapResult {
  const FirebaseBootstrapFailure(this.message);

  final String message;
}

abstract final class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize(
    AppEnvironment environment,
  ) async {
    try {
      await Firebase.initializeApp();
      await _activateAppCheck(environment);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      return const FirebaseBootstrapReady();
    } on FirebaseException catch (error) {
      return FirebaseBootstrapFailure(
        'Initialisation Firebase impossible (${error.code}) : '
        '${error.message ?? 'erreur inconnue'}.',
      );
    }
  }

  static Future<void> _activateAppCheck(AppEnvironment environment) async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: environment.isDevelopment
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: environment.isDevelopment
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
  }
}
