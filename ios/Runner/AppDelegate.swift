import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure the [DEFAULT] FirebaseApp synchronously here, BEFORE
    // super.application(...) and BEFORE Flutter's Dart code runs.
    // Without this call, Dart-side Firebase.initializeApp() throws
    // "[core/no-app] No Firebase App '[DEFAULT]' has been created" on
    // iOS — the FlutterImplicitEngineDelegate pattern doesn't bootstrap
    // [FIRApp configure] from GoogleService-Info.plist the way the
    // older AppDelegate pattern did.
    //
    // Guard against malformed/missing plist (v1.11.0+42 shipped one
    // with a placeholder GOOGLE_APP_ID): if FirebaseApp.configure()
    // throws an Objective-C exception, swallow it so the app still
    // launches. main.dart's try/catch around Firebase.initializeApp()
    // will then log the failure and continue in degraded mode (auth
    // and cloud sync don't work, but local features do).
    NSSetUncaughtExceptionHandler { exception in
      NSLog("FirebaseApp.configure() threw: \(exception)")
    }
    FirebaseApp.configure()
    NSSetUncaughtExceptionHandler(nil)
    // Device capability channel — Phase C RAM gate (see MainActivity.kt).
    if let controller = window?.rootViewController as? FlutterViewController {
      let deviceChannel = FlutterMethodChannel(
        name: "com.awing.learning/device_capability",
        binaryMessenger: controller.binaryMessenger
      )
      deviceChannel.setMethodCallHandler { (call, result) in
        if call.method == "getMemoryInfo" {
          let total = ProcessInfo.processInfo.physicalMemory
          let totalMb = Int64(total / (1024 * 1024))
          // iOS doesn't easily expose "available" RAM — return total for both
          // and let the Dart side use a conservative threshold.
          result([
            "totalRamMb": totalMb,
            "availableRamMb": totalMb,
            "lowMemory": false,
            "platform": "ios"
          ])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the asset-pack platform channel — iOS counterpart to
    // Android's MainActivity.kt PAD reader. Reads bundled assets out of
    // Runner.app/PADAssets/ via Bundle.main. Channel name and methods
    // match com.awing.learning/asset_pack on Android exactly.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AssetPackHandler") {
      AssetPackHandler.register(with: registrar.messenger())
    }
  }
}
