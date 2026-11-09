import UIKit
import MapKit
import WebKit

class MainSplitViewController: UIViewController, WKNavigationDelegate {
    
    // Hai khung chứa chính: Trái (Bản đồ) và Phải (Trình duyệt nhạc web)
    let leftContainerView = UIView()
    let rightContainerView = UIView()
    let dividerView = UIView()
    
    // Constraint điều chỉnh độ rộng màn hình trái
    var leftWidthConstraint: NSLayoutConstraint!
    
    // Tỷ lệ chia màn hình mặc định (0.5 tương đương 50/50)
    private var currentSplitRatio: CGFloat = 0.5
    
    // Trạng thái phóng to toàn màn hình của bản đồ
    private var isExpanded = false
    private var savedSplitRatio: CGFloat = 0.5
    
    // Các thành phần nội dung bên trong
    private var mapView: MKMapView!
    private var musicWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupViews()
        setupConstraints()
        setupGestures()
        setupMapAndBrowser()
        
        // Kích hoạt hiển thị bong bóng tốc độ nổi
        SpeedHUDManager.shared.showHUD()
    }
    
    private func setupViews() {
        leftContainerView.translatesAutoresizingMaskIntoConstraints = false
        rightContainerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        
        leftContainerView.backgroundColor = .black
        rightContainerView.backgroundColor = .black
        
        // Sử dụng màu cam đặc trưng (#DB5304) cho thanh kéo ở giữa
        dividerView.backgroundColor = UIColor(red: 0.86, green: 0.33, blue: 0.02, alpha: 1.0)
        
        view.addSubview(leftContainerView)
        view.addSubview(rightContainerView)
        view.addSubview(dividerView)
    }
    
    private func setupConstraints() {
        leftWidthConstraint = leftContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: currentSplitRatio)
        
        NSLayoutConstraint.activate([
            // Khung Bản đồ (Bên trái)
            leftContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            leftContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftWidthConstraint,
            
            // Thanh kéo tỷ lệ (Divider ở giữa)
            dividerView.leadingAnchor.constraint(equalTo: leftContainerView.trailingAnchor),
            dividerView.topAnchor.constraint(equalTo: view.topAnchor),
            dividerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: 8), // Độ dày vừa đủ để thao tác trên ô tô
            
            // Khung Nhạc web (Bên phải)
            rightContainerView.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor),
            rightContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            rightContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // Hàm cập nhật multiplier đúng chuẩn UIKit (thay thế constraint cũ bằng constraint mới)
    private func updateLeftWidthMultiplier(_ multiplier: CGFloat) {
        NSLayoutConstraint.deactivate([leftWidthConstraint])
        leftWidthConstraint = leftContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier)
        NSLayoutConstraint.activate([leftWidthConstraint])
    }
    
    private func setupGestures() {
        // 1. Cử chỉ kéo thanh Divider để thay đổi tỷ lệ (4-6, 7-3,...)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDividerPan(_:)))
        dividerView.addGestureRecognizer(panGesture)
        dividerView.isUserInteractionEnabled = true
        
        // 2. Cử chỉ chạm vào khung bản đồ (Trái) để phóng to full màn hình hoặc thu nhỏ lại
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap))
        leftContainerView.addGestureRecognizer(tapGesture)
        leftContainerView.isUserInteractionEnabled = true
    }
    
    private func setupMapAndBrowser() {
        // --- 1. Nhúng Bản đồ vào khung trái ---
        mapView = MKMapView(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        mapView.overrideUserInterfaceStyle = .dark // Giao diện tối phù hợp không gian xe
        
        leftContainerView.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: leftContainerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: leftContainerView.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: leftContainerView.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: leftContainerView.bottomAnchor)
        ])
        
        // --- 2. Nhúng Trình duyệt web nghe nhạc vào khung phải ---
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.allowsInlineMediaPlayback = true
        if #available(iOS 14.0, *) {
            webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        musicWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        musicWebView.translatesAutoresizingMaskIntoConstraints = false
        musicWebView.navigationDelegate = self
        musicWebView.scrollView.isScrollEnabled = true
        musicWebView.overrideUserInterfaceStyle = .dark
        
        rightContainerView.addSubview(musicWebView)
        NSLayoutConstraint.activate([
            musicWebView.leadingAnchor.constraint(equalTo: rightContainerView.leadingAnchor),
            musicWebView.trailingAnchor.constraint(equalTo: rightContainerView.trailingAnchor),
            musicWebView.topAnchor.constraint(equalTo: rightContainerView.topAnchor),
            musicWebView.bottomAnchor.constraint(equalTo: rightContainerView.bottomAnchor)
        ])
        
        // Load trang web nghe nhạc mặc định
        if let musicURL = URL(string: "https://music.youtube.com") {
            let request = URLRequest(url: musicURL)
            musicWebView.load(request)
        }
    }
    
    @objc private func handleDividerPan(_ gesture: UIPanGestureRecognizer) {
        guard !isExpanded else { return }
        
        let translation = gesture.translation(in: view)
        let totalWidth = view.bounds.width
        var newWidth = leftContainerView.bounds.width + translation.x
        
        // Giới hạn tỷ lệ kéo trong khoảng từ 30% đến 70% màn hình
        let minWidth: CGFloat = totalWidth * 0.3
        let maxWidth: CGFloat = totalWidth * 0.7
        
        if newWidth < minWidth { newWidth = minWidth }
        if newWidth > maxWidth { newWidth = maxWidth }
        
        currentSplitRatio = newWidth / totalWidth
        updateLeftWidthMultiplier(currentSplitRatio)
        view.layoutIfNeeded()
        
        gesture.setTranslation(.zero, in: view)
    }
    
    @objc private func handleMapTap() {
        if !isExpanded {
            savedSplitRatio = currentSplitRatio
        }
        
        isExpanded.toggle()
        
        let targetMultiplier: CGFloat = isExpanded ? 1.0 : savedSplitRatio
        updateLeftWidthMultiplier(targetMultiplier)
        dividerView.isHidden = isExpanded
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
            self.rightContainerView.alpha = self.isExpanded ? 0.0 : 1.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}
