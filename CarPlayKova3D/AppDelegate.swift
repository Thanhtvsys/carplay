import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Khởi tạo cửa sổ chính của app
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainSplitViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}
