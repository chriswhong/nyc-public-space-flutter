import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let associatedDomains = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.associated-domains") as? [String] {
        print("Associated Domains: \(associatedDomains)")
    } else {
        print("No Associated Domains found")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
