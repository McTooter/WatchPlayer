import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let listVC = ViewController()
        listVC.title = "WatchPlayer"
        window?.rootViewController = UINavigationController(rootViewController: listVC)
        window?.makeKeyAndVisible()
        return true
    }
}
