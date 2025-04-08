import UIKit
import WebKit
import SafariServices

public class WepinModal: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView?
    private var viewController: UIViewController?
    private var modalVC: UIViewController?
    private var jsProcessor: ((String, WKWebView, @escaping (String) -> Void) -> Void)?

    public func openModal(on parent: UIViewController, url: String, jsProcessor: @escaping (String, WKWebView, @escaping (String) -> Void) -> Void) {
        self.jsProcessor = jsProcessor

        DispatchQueue.main.async {
            let config = WKWebViewConfiguration()
            let contentController = WKUserContentController()
            contentController.add(self, name: "post")
            config.userContentController = contentController
            config.preferences.javaScriptEnabled = true
            config.allowsInlineMediaPlayback = true
            
            let webView = WKWebView(frame: .zero, configuration: config)
            self.webView = webView
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never
            webView.translatesAutoresizingMaskIntoConstraints = false
            
//            if #available(iOS 16.4, *) {
//                webView.isInspectable = true
//            }
            
            if let url = URL(string: url) {
                let request = URLRequest(url: url)
                webView.load(request)
            }
            
            let modalVC = UIViewController()
            modalVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            modalVC.modalPresentationStyle = .overFullScreen//.fullScreen
            modalVC.view.addSubview(webView)
            
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: modalVC.view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: modalVC.view.trailingAnchor),
                webView.topAnchor.constraint(equalTo: modalVC.view.safeAreaLayoutGuide.topAnchor),
                webView.bottomAnchor.constraint(equalTo: modalVC.view.bottomAnchor)
            ])
            
            parent.present(modalVC, animated: true, completion: nil)
            
            self.modalVC = modalVC
        }
    }

    public func closeModal() {
        DispatchQueue.main.async {
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: "post")
            self.webView?.removeFromSuperview()
            self.webView = nil
            self.modalVC?.dismiss(animated: true, completion: nil)
            self.modalVC = nil
        }
    }

    // MARK: - JavaScript Handler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "post", let body = message.body as? String {
            jsProcessor?(body, webView!) { [weak self] response in
                self?.callJavascript(method: "onResponse", args: [response])
            }
        }
    }

    private func callJavascript(method: String, args: [String]) {
        let params = args.map { "'\($0.replacingOccurrences(of: "'", with: "\\'"))'" }.joined(separator: ",")
        let js = "try {\(method)(\(params));} catch (e) { console.error(e); }"
        DispatchQueue.main.async {
            self.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // ✅ ✅✅ window.open() 대응
        public func webView(_ webView: WKWebView,
                            createWebViewWith configuration: WKWebViewConfiguration,
                            for navigationAction: WKNavigationAction,
                            windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                print("window.open intercepted: \(url)")
                openInExternalBrowser(url: url)
            }
            return nil
        }

    // MARK: - Navigation Delegate (optional)
//    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
//                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        if let url = navigationAction.request.url, !url.absoluteString.hasPrefix("http") {
//            openInExternalBrowser(url: url)
//            decisionHandler(.cancel)
//        } else {
//            decisionHandler(.allow)
//        }
//    }

//    public func openInExternalBrowser(url: URL) {
//        if let topVC = modalVC {
//            let safariVC = SFSafariViewController(url: url)
//            topVC.present(safariVC, animated: true, completion: nil)
//        }
//    }
    
    public func openInExternalBrowser(url: URL) {
        guard let topVC = modalVC ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        DispatchQueue.main.async {
            let safariVC = SFSafariViewController(url: url)
            if topVC.presentedViewController == nil {
                topVC.present(safariVC, animated: true, completion: nil)
            } else {
                topVC.presentedViewController?.present(safariVC, animated: true, completion: nil)
            }
        }
    }
}
