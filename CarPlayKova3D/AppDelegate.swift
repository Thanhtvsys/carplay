import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Khởi tạo cửa sổ ứng dụng phủ kín màn hình
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Gắn ViewController chính của bạn làm gốc (Thay MainSplitViewController bằng UIViewController thực tế của bạn nếu cần)
        window?.rootViewController = MainSplitViewController()
        
        window?.makeKeyAndVisible()
        return true
    }
}
