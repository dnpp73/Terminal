import UIKit
import WebKit

extension WKWebViewConfiguration {
    static func htermConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = false // iPhone default: false, iPad default: true
        configuration.allowsAirPlayForMediaPlayback = false // default: true
        configuration.allowsPictureInPictureMediaPlayback = false // default: true
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.setValue(true as Bool, forKey: "allowFileAccessFromFileURLs")
        configuration.preferences.setValue(true as Bool, forKey: "shouldAllowUserInstalledFonts")
        configuration.selectionGranularity = .character
        return configuration
    }
}

private let jsonEncoder = JSONEncoder()

extension WKWebView {
    func evaluateOneArgumentJavaScript<T: Encodable>(functionName: String, arg: T, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard let jsonData = try? jsonEncoder.encode([arg]) else {
            return
        }
        guard let json = String(data: jsonData, encoding: .utf8) else {
            return
        }
        let javaScript = functionName + "(" + json + "[0])"
        evaluateJavaScript(javaScript, completionHandler: completionHandler)
    }
}
