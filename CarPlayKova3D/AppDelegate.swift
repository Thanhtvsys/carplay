import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Không khởi tạo UIWindow thủ công ở đây khi ứng dụng dùng Scene Lifecycle
        return true
    }

    // MARK: - UISceneSession Lifecycle (Bắt buộc phải có để nhận diện CarPlay)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        // Kiểm tra nếu kết nối đến từ màn hình CarPlay
        if connectingSceneSession.role.rawValue == "CPTemplateApplicationSceneSessionRoleApplication" {
            return UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
        }
        
        // Mặc định cho màn hình điện thoại iPhone
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Dọn dẹp session bị hủy nếu cần
    }
}
