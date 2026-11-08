import UIKit
import Capacitor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        // Started by a chickencoops.ai link tapped in another app, or a home screen quick action:
        // the app opens that page once it is up.
        if let activity = connectionOptions.userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb }),
           let url = activity.webpageURL {
            RootViewController.pendingURL = url
        }
        if let item = connectionOptions.shortcutItem, let url = SceneDelegate.url(for: item) {
            RootViewController.pendingURL = url
        }
        // Started from the home screen widget.
        if let url = connectionOptions.urlContexts.first?.url, SceneDelegate.isSite(url) {
            RootViewController.pendingURL = url
        }

        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    /// A tap on the home screen widget while the app is running.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url, SceneDelegate.isSite(url) { open(url) }
        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
    }

    static func isSite(_ url: URL) -> Bool {
        // The site's host comes from www/app.json ("host").
        return (url.scheme == "https" || url.scheme == "http") && AppConfig.shared.isOwn(url)
    }

    /// A chickencoops.ai link tapped in Messages, Mail, X or Safari while the app is running.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            open(url)
        }
        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
    }

    /// Press and hold the app icon: Plan a coop, Community, Reels.
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        guard let url = SceneDelegate.url(for: shortcutItem) else { completionHandler(false); return }
        open(url)
        completionHandler(true)
    }

    static func url(for item: UIApplicationShortcutItem) -> URL? {
        switch item.type {
        case "coop.plan": return URL(string: "https://chickencoops.ai/planner")
        case "coop.community": return URL(string: "https://chickencoops.ai/?qcf_feed=1")
        case "coop.reels": return URL(string: "https://chickencoops.ai/reels/")
        default: return nil
        }
    }

    private func open(_ url: URL) {
        RootViewController.pendingURL = url
        NotificationCenter.default.post(name: .coopAppOpenURL, object: url)
    }
}
