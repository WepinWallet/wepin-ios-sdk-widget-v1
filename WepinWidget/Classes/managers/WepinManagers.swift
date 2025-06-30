import Foundation
import UIKit
import WebKit
import WepinCore
import WepinCommon
import WepinLogin

class WepinWidgetManager {
    // MARK: - Singleton
    static let shared = WepinWidgetManager()
    private init() {}
    
    // MARK: - Properties
    var wepinWebViewManager: WepinWebViewManager?
    var wepinLoginLib: WepinLogin?
    var appId: String = ""
    var appKey: String = ""
    var domain: String = ""
    var version: String = ""
    var sdkType: String = ""
    var wepinAttributes: WepinAttributeWithProviders?
    var loginProviderInfos: [LoginProviderInfo] = []
    private var specifiedEmail: String = ""
    internal var currentWepinRequest: [String: Any]? = nil // 웹뷰의 get_sdk_request 요청에 대한 응답 Request
    public var currentViewController :UIViewController?
    
    // MARK: - Public Methods
    func initialize(params: WepinWidgetParams, attributes: WepinWidgetAttribute?, platformType: String? = "ios") async throws {
        appId = params.appId
        appKey = params.appKey
        
        guard let url = try WepinCommon.getWepinSdkUrl(appKey: appKey)["wepinWebview"] else {
            throw WepinError.invalidAppKey
        }
        
        domain = Bundle.main.bundleIdentifier ?? ""
        sdkType = "\(platformType ?? "ios")-sdk"
        
        // TODO: version 가져오는 방법!!
        version = Bundle(for: WepinWidget.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        
        wepinAttributes = WepinAttributeWithProviders(defaultLanguage: attributes?.defaultLanguage, defaultCurrency: attributes?.defaultCurrency)
                
        try await WepinCore.shared.initialize(appId: appId, appKey: appKey, domain: domain, sdkType: sdkType, version: version)
            
        wepinWebViewManager = WepinWebViewManager(params: params, baseUrl: url)
        
        let wepinLoginParams = WepinLoginParams(appId: appId, appKey: appKey)
        wepinLoginLib = WepinLogin(wepinLoginParams)
        _ = try await wepinLoginLib?.initialize()
    }
    
    func setSpecifiedEmail(_ email: String) {
        specifiedEmail = email
    }
    
    func getSpecifiedEmail() -> String{
        return specifiedEmail
    }

    
    func finalize() {
        wepinLoginLib?.finalize()
        wepinWebViewManager = nil
        WepinCore.shared.finalize()
        wepinAttributes = nil
        loginProviderInfos.removeAll()
        specifiedEmail = ""
        currentWepinRequest = nil
        wepinLoginLib = nil
    }
}


public class WepinWidgetAttributeWithProviders : Codable {
    public var defaultLanguage: String
    public var defaultCurrency: String
    public var loginProviders: [String]

    public init(defaultLanguage: String = "en",
                defaultCurrency: String = "USD",
                loginProviders: [String]? = []) {
        self.loginProviders = loginProviders ?? []
        self.defaultLanguage = defaultLanguage
        self.defaultCurrency = defaultCurrency
    }
    
    func toDictionary() -> [String: AnyCodable] {
            let dict: [String: AnyCodable] = [
                "defaultLanguage": AnyCodable(defaultLanguage),
                "defaultCurrency": AnyCodable(defaultCurrency),
                "loginProviders": AnyCodable(loginProviders) // ← 바로 넣기
            ]
            return dict
        }
}
