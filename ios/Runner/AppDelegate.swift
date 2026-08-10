import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // ── Explicitly trigger APNs registration ──────────────────────────
    // firebase_messaging normally triggers this automatically, but the
    // implicit-engine plugin registration pattern used in this project
    // (see didInitializeImplicitFlutterEngine below) can register plugins
    // too late for that automatic trigger to fire reliably. Calling this
    // directly guarantees iOS attempts registration regardless of timing.
    application.registerForRemoteNotifications()

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ── APNs registration diagnostics ──────────────────────────────────
  override func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ APNs registered successfully. Device token: \(tokenString)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ APNs registration FAILED: \(error.localizedDescription)")
    print("❌ Full error: \(error)")
  }
}