import Foundation
import WepinLogin
import WebKit
import WepinCommon
import WepinCore

struct Command {
    static let CMD_READY_TO_WIDGET = "ready_to_widget"
    static let CMD_GET_SDK_REQUEST = "get_sdk_request"
    static let CMD_CLOSE_WEPIN_WIDGET = "close_wepin_widget"
    static let CMD_SET_LOCAL_STORAGE = "set_local_storage"
    static let CMD_SET_USER_EMAIL = "set_user_email"
    static let CMD_GET_CLIPBOARD = "get_clipboard"
    static let CMD_GET_LOGIN_INFO = "get_login_info"
    
    // Request Commands
    static let CMD_REGISTER_WEPIN = "register_wepin"
    static let CMD_SEND_TRANSACTION_WITHOUT_PROVIDER = "send_transaction_without_provider"
    static let CMD_RECEIVE_ACCOUNT = "receive_account"
    
    private static let responseCommands: Set<String> = [
        CMD_REGISTER_WEPIN,
        CMD_SEND_TRANSACTION_WITHOUT_PROVIDER,
        CMD_RECEIVE_ACCOUNT
    ]
    
    static func isResponseCommand(command: String) -> Bool {
        return responseCommands.contains(command)
    }
}

struct State {
    // Commands for JS processor
    static let STATE_SUCCESS = "SUCCESS"
    static let STATE_ERROR = "ERROR"
}


class JSProcessor {
    static func processRequest(request: String, webView: WKWebView, callback: @escaping (String) -> Void) {
        do {
            let jsonData = request.data(using: .utf8)!
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            let headerObject = jsonObject["header"] as! [String: Any]
            let bodyObject = jsonObject["body"] as! [String: Any]
            let command = bodyObject["command"] as! String
            var jsResponse: JSResponse? = nil
            
            var id: Int = -1
            var requestFrom: String = ""
            
            if Command.isResponseCommand(command: command) {
                guard let headerId = headerObject["id"] as? Int,
                      let _ = headerObject["response_to"] as? String,
                      let responseFrom = headerObject["response_from"] as? String else {
                    print("Invalid message format for response command: missing required fields")
                    return
                }
                id = headerId
                requestFrom = responseFrom
            } else {
                guard let headerId = headerObject["id"] as? Int,
                      let _ = headerObject["request_to"] as? String,
                      let requestFromValue = headerObject["request_from"] as? String else {
                    print("Invalid message format for request command: missing required fields")
                    return
                }
                id = headerId
                requestFrom = requestFromValue
            }
            
            
            switch command {
            case Command.CMD_READY_TO_WIDGET:
                print("CMD_READY_TO_WIDGET")
                let appKey = WepinWidgetManager.shared.appKey
                let appId = WepinWidgetManager.shared.appId
                let domain = WepinWidgetManager.shared.domain
                let platform = 3 // ios: 3
                let type = WepinWidgetManager.shared.sdkType
                let version = WepinWidgetManager.shared.version
                let attributes = WepinWidgetManager.shared.wepinAttributes
                let storageData = WepinCore.shared.storage.getAllStorage()
                jsResponse = JSResponse.Builder(
                    id: "\(id)",
                    requestFrom: requestFrom,
                    command: command,
                    state: State.STATE_SUCCESS
                ).setBodyData(parameter: JSResponse.Builder.ReadyToWidgetBodyData(
                    appKey: appKey,
                    appId: appId,
                    domain: domain,
                    platform: platform,
                    type: type,
                    version: version,
                    localData: convertToAnyCodableDictionary(storageData),
                    attributes: attributes
                ).toDictionary()).build()
            case Command.CMD_GET_SDK_REQUEST:
                print("CMD_GET_SDK_REQUEST")
                let requestData: AnyCodable
                
                if let currentRequest = WepinWidgetManager.shared.currentWepinRequest {
                    requestData = AnyCodable(convertToAnyCodableDictionary(currentRequest))
                } else {
                    requestData = AnyCodable("No request")
                }
                
                jsResponse = JSResponse.Builder(
                    id: "\(id)",
                    requestFrom: requestFrom,
                    command: command,
                    state: State.STATE_SUCCESS
                ).setBodyData(parameter: requestData)
                    .build()
            case Command.CMD_SET_LOCAL_STORAGE:
                print("CMD_SET_LOCAL_STORAGE")
                do {
                    guard let paramObject = bodyObject["parameter"] as? [String: Any],
                          let dataObject = paramObject["data"] as? [String: Any] else {
                        print("Invalid parameter format")
                        return
                    }
                    
                    var storageDataMap: [String: Codable] = [:]
                    // 데이터 처리 로직 구현
                    for (key, value) in dataObject {
                        let storageValue: Codable
                        if let jsonObject = value as? [String: Any] {
                            // Dictionary를 JSON String으로 변환
                            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                storageValue = jsonString
                            } else {
                                throw NSError(domain: "JSONSerialization", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON to String"])
                            }
                        } else if let stringValue = value as? String {
                            // String 값 처리
                            storageValue = stringValue
                        } else if let intValue = value as? Int {
                            // Int 값 처리
                            storageValue = intValue
                        } else {
                            // 지원되지 않는 데이터 타입 예외 처리
                            throw NSError(domain: "UnsupportedDataType", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unsupported data type for key: \(key)"])
                        }
                        // 처리된 값을 storageDataMap에 추가
                        storageDataMap[key] = storageValue
                    }
                    
                    WepinCore.shared.storage.setAllStorage(data: storageDataMap)
                    if storageDataMap["user_info"] != nil {
                        WepinWidgetManager.shared.wepinWebViewManager?.completeResponseWepinUserDeferred(success: true)
                    }
                    jsResponse = JSResponse.Builder(
                        id: "\(id)",
                        requestFrom: requestFrom,
                        command: command,
                        state: State.STATE_SUCCESS
                    ).build()
                } catch {
                    print("Error processing JSON data: \(error.localizedDescription)")
                    //                    throw WepinError.generalUnKnownEx(error.localizedDescription)
                }
            case Command.CMD_SET_USER_EMAIL:
                print("CMD_SET_USER_EMAIL")
                let email = WepinWidgetManager.shared.getSpecifiedEmail()
                jsResponse = JSResponse.Builder(
                    id: "\(id)", requestFrom: requestFrom,
                    command: command,
                    state: State.STATE_SUCCESS
                ).setBodyData(parameter:
                                JSResponse.Builder.SetEmailBodyData(email:email).toDictionary()
                ).build()
            case Command.CMD_GET_CLIPBOARD:
                print("CMD_GET_CLIPBOARD")
                jsResponse = JSResponse.Builder(
                    id: "\(id)", requestFrom: requestFrom,
                    command: command,
                    state: State.STATE_SUCCESS
                ).build()
                // TODO: 클립보드 라이브러리 연동 후..
                // jsResponse?.body.data = WepinWidgetManager.shared.getClipboard()
            case Command.CMD_GET_LOGIN_INFO:
                print("CMD_GET_LOGIN_INFO")
                Task {
                    do {
                        // parameter 추출
                        guard let parameter = bodyObject["parameter"] as? [String: Any],
                              let provider = parameter["provider"] as? String,
                              !provider.isEmpty else {
                            throw NSError(domain: "InvalidProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid provider"])
                        }
                        
                        // clientId 매핑
                        let providerToClientIdMap = WepinWidgetManager.shared.loginProviderInfos.reduce(into: [String: String]()) {
                            $0[$1.provider] = $1.clientId
                        }
                        guard let clientId = providerToClientIdMap[provider] else {
                            throw NSError(domain: "MissingClientId", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing clientId for provider"])
                        }
                        
                        // ViewController 및 wepinLoginLib 체크
                        guard let loginLib = WepinWidgetManager.shared.wepinLoginLib else {
              throw WepinError.loginFailed
            }
            
            let viewControllerForOAuth: UIViewController
            
            if let modalVC = WepinWidgetManager.shared.wepinWebViewManager?.wepinModal.getCurrentModalViewController() {
              // Modal의 ViewController 사용
              viewControllerForOAuth = modalVC
              print("🔧 Using Modal ViewController for OAuth")
            } else if let currentVC = WepinWidgetManager.shared.currentViewController {
              // Fallback: 기존 방식
              viewControllerForOAuth = currentVC
              print("🔧 Using Current ViewController for OAuth")
            } else {
              throw WepinError.loginFailed
            }
                        
                        // 로그인 요청
                        let oauthParams = WepinLoginOauth2Params(provider: provider, clientId: clientId)
                        let loginResponse = try await loginLib.loginWithOauthProvider(params: oauthParams, viewController: viewControllerForOAuth)
                        do {
                            // Firebase 로그인
                            let firebaseRes: WepinLoginResult?
                            switch loginResponse.type {
                            case .idToken:
                                let idTokenParams = WepinLoginOauthIdTokenRequest(idToken: loginResponse.token)
                                firebaseRes = try await loginLib.loginWithIdToken(params: idTokenParams)
                            case .accessToken:
                                let accessTokenParams = WepinLoginOauthAccessTokenRequest(provider: provider, accessToken: loginResponse.token)
                                firebaseRes = try await loginLib.loginWithAccessToken(params: accessTokenParams)
                            }
                            
                            // 성공 응답
                            let jsResponse = JSResponse.Builder(
                                id: "\(id)",
                                requestFrom: requestFrom,
                                command: command,
                                state: State.STATE_SUCCESS
                            ).setBodyData(parameter: firebaseRes?.toDictionary()).build()
                            
                            let responseData = try JSONEncoder().encode(jsResponse)
                            if let responseString = String(data: responseData, encoding: .utf8) {
                                //print("JSProcessor Response: \(responseString)")
                                
                                // 웹뷰가 존재하는지 안전하게 체크
                                //                        guard let webView = webView else {
                                //                            print("Error: WebView is nil")
                                //
                                //                            return
                                //                        }
                                
                                // 웹뷰로 응답 전송
                                sendResponseToWebView(response: responseString, webView: webView)
                                
                            }
                        } catch {
                            print("Error encoding JSResponse: \(error.localizedDescription)")
                            if let wepinError = error as? WepinError,
                               case .requiredSignupEmail = wepinError {
                                
                                print("error: requiredSignupEmail detected")
                                
                                var responseBody: [String: AnyCodable] = ["result": AnyCodable("no_email")]
                                
                                // loginResponse.type에 따라 적절한 토큰 타입 설정
                                switch loginResponse.type {
                                case .idToken:
                                    responseBody["idToken"] = AnyCodable(loginResponse.token)
                                case .accessToken:
                                    responseBody["accessToken"] = AnyCodable(loginResponse.token)
                                }
                                
                                let jsResponse = JSResponse.Builder(
                                    id: "\(id)",
                                    requestFrom: requestFrom,
                                    command: command,
                                    state: State.STATE_SUCCESS
                                ).setBodyData(parameter: responseBody).build()
                                
                                let responseData = try JSONEncoder().encode(jsResponse)
                                if let responseString = String(data: responseData, encoding: .utf8) {
                                    sendResponseToWebView(response: responseString, webView: webView)
                                }
                                
                            } else {
                                // 다른 Firebase 에러는 외부 catch로 전달
                                throw error
                            }
                        }
                        //                        if let responseData = try? JSONSerialization.data(withJSONObject: jsResponse!, options: []),
                        //                           let responseString = String(data: responseData, encoding: .utf8) {
                        //                            callback(responseString)
                        //                        }
                        
                    } catch {
                        // 에러 응답
                        // 에러 state 를 STATE_ERROR 로 하면 user_canceled error 못잡음
                        
                        jsResponse = JSResponse.Builder(
                            id: "\(id)",
                            requestFrom: requestFrom,
                            command: command,
                            state: State.STATE_SUCCESS
                        ).setBodyData(parameter: ["error": AnyCodable(error.localizedDescription)]).build()
                        
                        
                        do {
                            let responseData = try JSONEncoder().encode(jsResponse)
                            if let responseString = String(data: responseData, encoding: .utf8) {
                                //print("JSProcessor Response: \(responseString)")
                                
                                // 웹뷰가 존재하는지 안전하게 체크
                                //                        guard let webView = webView else {
                                //                            print("Error: WebView is nil")
                                //
                                //                            return
                                //                        }
                                
                                // 웹뷰로 응답 전송
                                sendResponseToWebView(response: responseString, webView: webView)
                                
                            }
                        } catch {
                            print("Error encoding JSResponse: \(error.localizedDescription)")
                        }
                        //                        if let responseData = try? JSONSerialization.data(withJSONObject: jsResponse!, options: []),
                        //                           let responseString = String(data: responseData, encoding: .utf8) {
                        //                            callback(responseString)
                        //                        }
                    }
                    return
                }
            case Command.CMD_CLOSE_WEPIN_WIDGET:
                jsResponse = nil
                WepinWidgetManager.shared.wepinWebViewManager?.closeWidget()
            case Command.CMD_REGISTER_WEPIN, Command.CMD_SEND_TRANSACTION_WITHOUT_PROVIDER, Command.CMD_RECEIVE_ACCOUNT:
                // ✅ request 자체를 그대로 async 작업을 기다리던 쪽으로 넘겨주기
                WepinWidgetManager.shared.wepinWebViewManager?.completeResponseDeferred(request)
            default:
                print("JSProcessor Response is null")
                return
            }
            // 7. JSResponse가 nil이 아닌 경우 JSON으로 변환하여 출력
            if let jsResponse = jsResponse {
                do {
                    let responseData = try JSONEncoder().encode(jsResponse)
                    if let responseString = String(data: responseData, encoding: .utf8) {
                        //print("JSProcessor Response: \(responseString)")
                        
                        // 웹뷰가 존재하는지 안전하게 체크
                        //                        guard let webView = webView else {
                        //                            print("Error: WebView is nil")
                        //
                        //                            return
                        //                        }
                        
                        // 웹뷰로 응답 전송
                        sendResponseToWebView(response: responseString, webView: webView)
                        
                    }
                } catch {
                    print("Error encoding JSResponse: \(error.localizedDescription)")
                }
            } else {
                print("Error: jsResponse is nil")
            }
            
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
    
    // 웹뷰에 응답하는 함수
    private static func sendResponseToWebView(response: String, webView: WKWebView) {
        // JavaScript 실행을 통해 웹뷰로 응답을 전송
        DispatchQueue.main.async {
            let message = "onResponse(" + response + ");"
            webView.evaluateJavaScript(message) { (result, error) in
                if let error = error {
                    print("Error executing JS command: \(error.localizedDescription)")
                }
            }
        }
    }
    
}

func convertToAnyCodable(_ value: Any) -> AnyCodable {
    if let dict = value as? [String: Any] {
        return AnyCodable(convertToAnyCodableDictionary(dict))
    } else if let array = value as? [Any] {
        return AnyCodable(array.map { convertToAnyCodable($0) })
    } else {
        return AnyCodable(value)
    }
}

func convertToAnyCodableDictionary(_ dictionary: [String: Any]) -> [String: AnyCodable] {
    var result: [String: AnyCodable] = [:]
    for (key, value) in dictionary {
        result[key] = convertToAnyCodable(value)
    }
    return result
}

func convertJsonToLocalStorageData(_ jsonString: String) -> Any? {
    // JSON 문자열을 Data로 변환
    guard let jsonData = jsonString.data(using: .utf8) else {
        print("Failed to convert JSON string to Data")
        return nil
    }
    
    // JSON 데이터 파싱
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
        return jsonObject
    } catch {
        print("Error parsing JSON data: \(error.localizedDescription)")
        return nil
    }
}


extension WepinLoginResult {
    func toDictionary() -> [String: AnyCodable] {
        return [
            "provider": AnyCodable(provider.rawValue),
            "token": AnyCodable(token.toDictionary())
        ]
    }
}

extension WepinFBToken {
    func toDictionary() -> [String: AnyCodable] {
        var result: [String: AnyCodable] = [:]
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.label {
                result[key] = AnyCodable(child.value)
            }
        }
        return result
    }
}
