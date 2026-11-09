import UIKit
import WebKit

class MainSplitViewController: UIViewController {

    private let leftContainerView = UIView()   // Khung bên trái chứa bản đồ (Google Maps / VietMap)
    private let rightWebView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        loadWebDashboard()
    }

    private func setupLayout() {
        // Dùng UIStackView chia đôi màn hình theo chiều ngang (Axis: Horizontal)
        let stackView = UIStackView(arrangedSubviews: [leftContainerView, rightWebView])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually // Chia đều 50% - 50% màn hình
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadWebDashboard() {
        if let url = URL(string: "https://datdatcarplay.alwaysdata.net") {
            let request = URLRequest(url: url)
            rightWebView.load(request)
        }
    }
}
