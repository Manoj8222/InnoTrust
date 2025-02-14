import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

@main
class AppDelegate: RCTAppDelegate {
  override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    self.moduleName = "CamOcrLibExample"
    self.dependencyProvider = RCTAppDependencyProvider()

    // You can add your custom initial props in the dictionary below.
    // They will be passed down to the ViewController used by React Native.
    self.initialProps = [:]

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    // Use your computer's IP address instead of localhost
    let jsCodeLocation = URL(string: "http://192.168.1.46:8081/index.bundle?platform=ios")
    // let jsCodeLocation = URL(string: "http://192.168.1.193:8081/index.bundle?platform=ios")
    
    return jsCodeLocation
#else
    // For production, use the bundled JS file
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}