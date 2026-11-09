import UIKit
import CarPlay

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?

    // Được gọi khi màn hình CarPlay kết nối thành công với thiết bị
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        print("[CarPlayKova3D] CarPlay đã kết nối thành công!")

        // Tạo giao diện danh sách hiển thị trên màn hình xe ô tô
        let section = CPListSection(items: [
            CPListItem(text: "CarPlayKova3D Dashboard", detailText: "Chạy ứng dụng tích hợp Web", image: UIImage(systemName: "car.fill"))
        ])
        
        let listTemplate = CPListTemplate(title: "CarPlay Kova3D", sections: [section])
        
        // Đẩy template ra màn hình chính của CarPlay
        interfaceController.setRootTemplate(listTemplate, animated: true, completion: nil)
    }

    // Được gọi khi ngắt kết nối CarPlay
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        print("[CarPlayKova3D] CarPlay đã ngắt kết nối.")
    }
}
