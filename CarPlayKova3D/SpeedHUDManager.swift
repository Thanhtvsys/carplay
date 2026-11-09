import UIKit
import CoreLocation

class SpeedHUDManager: NSObject, CLLocationManagerDelegate {
    static let shared = SpeedHUDManager()
    
    private var hudWindow: UIWindow?
    private var speedLabel: UILabel!
    private var locationManager: CLLocationManager!
    private var hudView: UIView!
    
    // MARK: - Các thông số tùy chỉnh nhanh (Customization Properties)
    private let hudSize: CGFloat = 105          // Kích thước đường kính bong bóng (tăng/giảm tu ý)
    private let themeOrange = UIColor(red: 0.86, green: 0.33, blue: 0.02, alpha: 1.0) // Màu cam #DB5304
    private let hudBackground = UIColor.black.withAlphaComponent(0.88) // Màu nền tối mờ
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Hiển thị bong bóng tốc độ nổi lên màn hình
    func showHUD() {
        guard hudWindow == nil else { return }
        
        // Tạo cửa sổ UIWindow độc lập nằm ở lớp trên cùng (.alert + 1)
        let windowFrame = CGRect(x: 35, y: 90, width: hudSize, height: hudSize)
        let window = UIWindow(frame: windowFrame)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        
        // Thiết kế giao diện bong bóng tròn, viền cam chủ đạo (#DB5304)
        hudView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: hudSize, height: hudSize)))
        hudView.backgroundColor = hudBackground
        hudView.layer.cornerRadius = hudSize / 2
        hudView.layer.borderWidth = 3.5
        hudView.layer.borderColor = themeOrange.cgColor
        
        // Hiệu ứng đổ bóng giúp bong bóng nổi bật trên mọi nền bản đồ
        hudView.layer.shadowColor = UIColor.black.cgColor
        hudView.layer.shadowOpacity = 0.7
        hudView.layer.shadowOffset = CGSize(width: 0, height: 4)
        hudView.layer.shadowRadius = 8.0
        
        // Label hiển thị số tốc độ thời gian thực
        speedLabel = UILabel(frame: hudView.bounds)
        speedLabel.textAlignment = .center
        speedLabel.numberOfLines = 2
        speedLabel.text = "0\nkm/h"
        speedLabel.textColor = .white
        
        // Tùy chỉnh font chữ sắc nét: Số to, đơn vị nhỏ gọn phía dưới
        let fontDescriptor = UIFont.systemFont(ofSize: 24, weight: .bold).fontDescriptor
        if let boldItalicDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            speedLabel.font = UIFont(descriptor: boldItalicDescriptor, size: 26)
        } else {
            speedLabel.font = UIFont.boldSystemFont(ofSize: 26)
        }
        
        hudView.addSubview(speedLabel)
        
        // Thêm cử chỉ kéo thả (Pan Gesture) để di chuyển bong bóng tự do khắp màn hình
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        hudView.addGestureRecognizer(panGesture)
        hudView.isUserInteractionEnabled = true
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        viewController.view.addSubview(hudView)
        
        window.rootViewController = viewController
        window.isHidden = false
        self.hudWindow = window
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let window = hudWindow else { return }
        let translation = gesture.translation(in: window)
        
        var center = window.center
        center.x += translation.x
        center.y += translation.y
        window.center = center
        
        gesture.setTranslation(.zero, in: window)
    }
    
    // MARK: - CLLocationManagerDelegate (Cập nhật tốc độ GPS thời gian thực)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // location.speed tính bằng m/s. Đổi sang km/h nhân với 3.6
        var speedInKmH: Double = 0
        if location.speed >= 0 {
            speedInKmH = location.speed * 3.6
        }
        
        DispatchQueue.main.async {
            let roundedSpeed = Int(round(speedInKmH))
            
            // Định dạng hiển thị: Số tốc độ màu trắng nổi bật, chữ km/h nhỏ màu cam (#DB5304) phía dưới
            let attributedString = NSMutableAttributedString(
                string: "\(roundedSpeed)\n",
                attributes: [.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 28)]
            )
            let subString = NSAttributedString(
                string: "km/h",
                attributes: [.foregroundColor: self.themeOrange, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)]
            )
            attributedString.append(subString)
            
            self.speedLabel.attributedText = attributedString
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Lỗi GPS HUD: \(error.localizedDescription)")
    }
}
