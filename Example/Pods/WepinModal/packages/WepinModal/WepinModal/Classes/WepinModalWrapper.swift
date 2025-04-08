@objcMembers
public class WepinModalWrapper: NSObject {
    private let modal = WepinModal()

    public static let shared = WepinModalWrapper()

    public func openModal(on viewController: UIViewController, url: String) {
        modal.openModal(on: viewController, url: url) { request, webView, callback in
            print("[WepinModalWrapper] JS Message Received: \(request)")
            callback("{\"header\": {\"id\": \"objc-default\", \"response_from\": \"objc\", \"response_to\": \"wepin_widget\"}, \"body\": {\"state\": \"SUCCESS\", \"data\": \"objc-default-response\"}}")
        }
    }

    public func closeModal() {
        modal.closeModal()
    }

    /// ✅ 외부 브라우저 열기 - Objective-C에서도 사용 가능
    public func openInExternalBrowser(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        modal.openInExternalBrowser(url: url)
    }
}
