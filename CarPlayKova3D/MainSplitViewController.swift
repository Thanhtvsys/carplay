import UIKit
import WebKit

class MainSplitViewController: UIViewController {

    // Khung bên trái (Menu chứa các nút chọn ứng dụng, điều hướng)
    private let leftMenuView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.1, alpha: 0.95) // Nền tối phong cách xe hơi
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Khung bên phải (Web View chiếm toàn màn hình)
    private let rightWebView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    // Nút bấm ẩn/hiện Menu (Nằm chồng lên góc màn hình)
    private lazy var toggleMenuButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("☰ Menu", for: .normal)
            button.setTitleColor(.white, for: .normal)
            // Sửa ở đây: Dùng withAlphaComponent(0.6) thay cho withAlpha60()
            button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            button.layer.cornerRadius = 8
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
            return button
        }()

    // Constraint điều khiển độ rộng của menu trái để ẩn/hiện
    private var leftMenuWidthConstraint: NSLayoutConstraint!
    private var isMenuVisible = false // Mặc định ẩn menu trái để web full màn hình

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWebDashboard()
    }

    private func setupUI() {
        view.backgroundColor = .black

        // 1. Thêm WebView (Khung phải hiển thị toàn màn hình trước)
        view.addSubview(rightWebView)
        
        // 2. Thêm Menu trái
        view.addSubview(leftMenuView)

        // 3. Thêm Nút Toggle Menu
        view.addSubview(toggleMenuButton)

        // Cài đặt Constraints
        leftMenuWidthConstraint = leftMenuView.widthAnchor.constraint(equalToConstant: 0) // Mặc định ẩn (width = 0)

        NSLayoutConstraint.activate([
            // Khung phải (Web) chiếm toàn bộ màn hình
            rightWebView.topAnchor.constraint(equalTo: view.topAnchor),
            rightWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rightWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rightWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Khung trái (Menu) neo ở cạnh trái
            leftMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            leftMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftMenuWidthConstraint,

            // Nút Toggle Menu nằm ở góc trên bên trái
            toggleMenuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            toggleMenuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            toggleMenuButton.widthAnchor.constraint(equalToConstant: 70),
            toggleMenuButton.heightAnchor.constraint(equalToConstant: 35)
        ])

        setupMenuContent()
    }

    // Thêm các nút chức năng vào menu bên trái
    private func setupMenuContent() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Nút mở Google Maps
        let mapsButton = createMenuButton(title: "🗺️ Google Maps", action: #selector(openGoogleMaps))
        // Nút thu gọn / tỉ lệ 4-6
        let ratioButton = createMenuButton(title: "📐 Chia đôi 4-6", action: #selector(toggleSplitRatio))

        stackView.addArrangedSubview(mapsButton)
        stackView.addArrangedSubview(ratioButton)

        leftMenuView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: leftMenuView.topAnchor, constant: 60),
            stackView.leadingAnchor.constraint(equalTo: leftMenuView.leadingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: leftMenuView.trailingAnchor, constant: 15),
            stackView.heightAnchor.constraint(equalToConstant: 120)
        ])
    }

    private func createMenuButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(white: 0.25, alpha: 1.0)
        btn.layer.cornerRadius = 6
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    private func loadWebDashboard() {
        if let url = URL(string: "https://datdatcarplay.alwaysdata.net") {
            rightWebView.load(URLRequest(url: url))
        }
    }

    // Sự kiện ẩn/hiện menu trái
    @objc private func toggleMenu() {
        isMenuVisible.toggle()
        leftMenuWidthConstraint.constant = isMenuVisible ? 220 : 0 // Độ rộng menu khi mở là 220pt

        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }

    // Sự kiện đổi tỷ lệ chia màn hình hoặc mở app ngoài
    @objc private func toggleSplitRatio() {
        // Tùy chỉnh độ rộng menu ở đây nếu muốn đổi tỷ lệ 4-6
        if leftMenuWidthConstraint.constant == 220 {
            leftMenuWidthConstraint.constant = view.bounds.width * 0.4 // Chiếm 40% màn hình (tỷ lệ 4-6)
        } else {
            leftMenuWidthConstraint.constant = 220
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func openGoogleMaps() {
        if let url = URL(string: "comgooglemaps://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        if let browserUrl = URL(string: "https://www.google.com/maps") {
            UIApplication.shared.open(browserUrl)
        }
    }
}
