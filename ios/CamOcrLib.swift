import Foundation
import UIKit

@objc(CamOcrLib)
class CamOcrLib: NSObject {

    @objc(multiply:withB:withResolver:withRejecter:)
    func multiply(a: Float, b: Float, resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        resolve(a * b)
    }

    @objc(getHelloWorld:withRejecter:)
    func getHelloWorld(resolve: RCTPromiseResolveBlock, reject: RCTPromiseRejectBlock) -> Void {
        resolve("HelloWorld")
    }

    @objc(showEkycUI:withRejecter:)
    func showEkycUI(resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
            let ekycViewController = EkycViewController()
            ekycViewController.resolve = resolve
            ekycViewController.reject = reject

            ekycViewController.modalPresentationStyle = .fullScreen

            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                rootViewController.present(ekycViewController, animated: true, completion: nil)
            } else {
                reject("NO_ROOT_VIEW_CONTROLLER", "Could not find root view controller", nil)
            }
        }
    }
}