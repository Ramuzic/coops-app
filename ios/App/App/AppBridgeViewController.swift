import UIKit
import Capacitor
import WebKit

/// Capacitor's web view, set up to sit between the status bar and the native tab bar.
class AppBridgeViewController: CAPBridgeViewController {

    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(CoopAppPlugin())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let web = webView else { return }
        // The root view already keeps the page below the status bar and above the
        // tab bar, so the page itself should not add any extra spacing.
        web.scrollView.contentInsetAdjustmentBehavior = .never
        // Swipe from the left edge to go back, like any iPhone app.
        web.allowsBackForwardNavigationGestures = true
        // Pages may not take over the screen with element full screen: inside a web view this can crash the app.
        // They use their own full-window view instead.
        if #available(iOS 15.4, *) { web.configuration.preferences.isElementFullscreenEnabled = false }
        web.isOpaque = false
        web.backgroundColor = AppConfig.shared.paperColor
        web.scrollView.backgroundColor = AppConfig.shared.paperColor

        // Screenshot mode (launch argument -CoopShot, used only by the screenshot
        // workflow): skip the web welcome screen unless -CoopShowGate is also given.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-CoopShot") && !args.contains("-CoopShowGate") {
            let js = "try{localStorage.setItem('ccsf_gate','1')}catch(e){}"
            web.configuration.userContentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        guard args.contains("-CoopShot") else { return }
        // -CoopCookies "a=1; b=2": a signed-in member for the screenshots (cookies made by the workflow).
        if let i = args.firstIndex(of: "-CoopCookies"), i + 1 < args.count {
            let store = web.configuration.websiteDataStore.httpCookieStore
            for pair in args[i + 1].components(separatedBy: ";") {
                let kv = pair.trimmingCharacters(in: .whitespaces)
                guard let eq = kv.firstIndex(of: "=") else { continue }
                let name = String(kv[..<eq]), value = String(kv[kv.index(after: eq)...])
                if name.isEmpty { continue }
                if let c = HTTPCookie(properties: [.domain: "chickencoops.ai", .path: "/", .name: name, .value: value, .secure: "TRUE", .expires: Date().addingTimeInterval(86400)]) {
                    store.setCookie(c)
                }
            }
        }
        // -CoopJS "code": runs on each page once it has loaded (for example to open full screen browsing).
        if let i = args.firstIndex(of: "-CoopJS"), i + 1 < args.count {
            web.configuration.userContentController.addUserScript(WKUserScript(source: args[i + 1], injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
    }
}
