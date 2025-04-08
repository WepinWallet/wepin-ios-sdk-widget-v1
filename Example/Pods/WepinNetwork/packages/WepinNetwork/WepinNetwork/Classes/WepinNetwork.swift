import Foundation
import WepinCommon

public class WepinNetwork {
    public static let shared = WepinNetwork()
    // MARK: - Properties
    private var baseUrl: String = ""
    private var appKey: String = ""
    private var domain: String = ""
    private var sdkType: String = ""
    private var version: String = ""
    private var accessToken: String?
    private var refreshToken: String?
    private var _initialized: Bool = false
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    
    // MARK: - Initialization
    public func initialize(appKey: String, domain: String, sdkType: String, version: String) throws {
        if _initialized { return }
        self.appKey = appKey
        self.domain = domain
        self.sdkType = sdkType
        self.version = version
        guard let url = try WepinCommon.getWepinSdkUrl(appKey: appKey)["sdkBackend"] else {
            throw WepinError.invalidAppKey
        }
        self.baseUrl = url
        _initialized = true
    }
    
    public func finalize() {
        appKey = ""
        domain = ""
        sdkType = ""
        version = ""
        baseUrl = ""
        clearAuthToken()
        _initialized = false
    }
    
    public func isInitialized() -> Bool {
        return _initialized
    }
    
    // MARK: - Auth Management
    public func setAuthToken(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
    }
    
    public func clearAuthToken() {
        self.accessToken = nil
        self.refreshToken = nil
    }
    
    // MARK: - Network Helpers
    private func createURLRequest(endpoint: String, method: String = "POST", body: [String: Any]? = nil) -> URLRequest? {
        guard let url = URL(string: baseUrl + endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        setDefaultHeaders(request: &request)
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        return request
    }
    
    private func setDefaultHeaders(request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue(domain, forHTTPHeaderField: "X-API-DOMAIN")
        request.setValue(sdkType, forHTTPHeaderField: "X-SDK-TYPE")
        request.setValue(version, forHTTPHeaderField: "X-SDK-VERSION")
        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: WepinError.networkError("No data received"))
                    return
                }
                do {
                    try self?.checkError(data: data, response: response)
                    
                    if data.isEmpty || String(data: data, encoding: .utf8) == "{}" {
                        if T.self == Bool.self {
                            continuation.resume(returning: true as! T)
                            return
                        }
                    }
                    
                    if T.self == String.self {
                        if let stringResponse = String(data: data, encoding: .utf8) {
                            continuation.resume(returning: stringResponse as! T)
                            return
                        } else {
                            continuation.resume(throwing: WepinError.parsingFailed("Response is not a valid UTF-8 string"))
                            return
                        }
                    }
                    let result = try JSONDecoder().decode(T.self, from: data)
                    continuation.resume(returning: result)
                } catch let decodeError as DecodingError {
                    switch decodeError {
                       case .typeMismatch(let type, let context):
                           print("Type mismatch: \(type), context: \(context)")
                       case .valueNotFound(let type, let context):
                           print("Value not found: \(type), context: \(context)")
                       case .keyNotFound(let key, let context):
                           print("Key not found: \(key), context: \(context)")
                       case .dataCorrupted(let context):
                           print("Data corrupted: \(context)")
                       @unknown default:
                           print("Unknown decoding error: \(decodeError)")
                       }
                    continuation.resume(throwing: WepinError.parsingFailed(decodeError.localizedDescription))
                } catch {
                    continuation.resume(throwing: error)
                }
//                do {
//                    try self?.checkError(data: data, response: response)
//                    let result = try JSONDecoder().decode(T.self, from: data)
//                    continuation.resume(returning: result)
//                } catch {
//                    continuation.resume(throwing: WepinError.parsingFailed)
//                }
            }.resume()
        }
    }
    
    func isErrorResponse (response: Data) -> String? {
        if let status = (try? JSONSerialization.jsonObject(with: response, options: []) as? [String: Any])?!["status"] as? Int {
            if status  >= 300 || status < 200 {
                let updatedJsonString = String(data: response, encoding: .utf8)
                return updatedJsonString
            }
        }
        return nil
    }
    
    private func checkError(data: Data, response: URLResponse?) throws {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse!.statusCode
        if (200...299).contains(statusCode) {
        } else {
            if let errorMessage = self.isErrorResponse(response: data) {
                throw WepinError.networkError(errorMessage)
            }else {
                let updatedJsonString = String(data: data, encoding: .utf8)
                throw WepinError.networkError(updatedJsonString ?? "statusCode: \(statusCode)")
            }
        }
    }
    
    func getRequest(request: URLRequest, completion: @escaping (Result<Any, Error>) -> Void) {
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(WepinError.networkError("No data received")))
                return
            }
            do {
                try self.checkError(data: data, response: response)
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                completion(.success(jsonResponse))
            } catch {
               completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - API Methods
    public func getOAuthProviderInfo() async throws -> [OAuthProviderInfo] {
        guard let request = createURLRequest(endpoint: "user/oauth-provider", method: "GET") else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func getRegex() async throws -> WepinRegex {
        guard let request = createURLRequest(endpoint: "user/regex", method: "GET") else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func getAppInfo() async throws -> Any {
        guard let request = createURLRequest(endpoint: "app/info?platform=3", method: "GET") else {
            throw WepinError.invalidRequest
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            getRequest(request: request) { result in
                switch result {
                case .success(let jsonResponse):
                    continuation.resume(returning: jsonResponse)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getFirebaseConfig() async throws -> String {
        guard let request = createURLRequest(endpoint: "user/firebase-config", method: "GET") else {
            throw WepinError.invalidRequest
        }
        
        let responseData: String = try await performRequest(request: request)
        
        if let decodedData = Data(base64Encoded: responseData) {
            let decodedString = String(data: decodedData, encoding: .utf8)
            
            let data = decodedString?.data(using: .utf8)
            if data == nil {
                throw WepinError.networkError("firebase config decode error")
            }
            if let apiKey = (try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any])??["apiKey"] as? String {
                return apiKey
            } else {
                throw WepinError.networkError("api key is not exist")
            }
        }
        
        return responseData
    }
    
    public func login(request: LoginRequest) async throws -> LoginResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/login", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        let loginResult: LoginResponse = try await performRequest(request: urlRequest)
        self.setAuthToken(access: loginResult.token.access, refresh: loginResult.token.refresh)
        return loginResult
    }
    
    public func logout(userId: String) async throws -> Bool {
        guard let request = createURLRequest(endpoint: "user/\(userId)/logout", method: "POST") else {
            throw WepinError.invalidRequest
        }
        
        let _: Bool = try await performRequest(request: request)
        clearAuthToken()
        return true
    }
        
//        return try await withCheckedThrowingContinuation { [weak self] continuation in
//            session.dataTask(with: request) { _, _, error in
//                if let error = error {
//                    continuation.resume(throwing: error)
//                    return
//                }
//                self?.clearAuthToken()
//                continuation.resume(returning: true)
//            }.resume()
//        }
//    }
    
    public func getAccessToken(userId: String) async throws -> GetAccessTokenResponse {
        let endpoint = "user/access-token?userId=\(userId)&refresh_token=\(refreshToken ?? "")"
        guard let request = createURLRequest(endpoint: endpoint, method: "GET") else {
            throw WepinError.invalidRequest
        }
        let res: GetAccessTokenResponse =  try await performRequest(request: request)
        self.setAuthToken(access: res.token, refresh: self.refreshToken!)
        return res
    }
    
    public func loginOAuthIdToken(request: LoginOauthIdTokenRequest) async throws -> LoginOauthIdTokenResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/oauth/login/id-token", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func loginOAuthAccessToken(request: LoginOauthAccessTokenRequest) async throws -> LoginOauthIdTokenResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/oauth/login/access-token", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func checkEmailExist(email: String) async throws -> CheckEmailExistResponse {
        let endpoint = "user/check-user?email=\(email)"
        guard let request = createURLRequest(endpoint: endpoint, method: "GET") else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: request)
    }
    
    public func getUserPasswordState(email: String) async throws -> PasswordStateResponse {
        let queryString = "email=\(email)"
        guard let url = URL(string: baseUrl + "user/password-state?\(queryString)") else {
            throw WepinError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        setDefaultHeaders(request: &urlRequest)
        return try await performRequest(request: urlRequest)
    }
    
    public func updateUserPasswordState(userId: String, request: PasswordStateRequest) async throws -> PasswordStateResponse {
        let endpoint = "user/\(userId)/password-state"
        guard let request = createURLRequest(endpoint: endpoint, method: "PATCH", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: request)
    }
    
    public func verify(request: VerifyRequest) async throws -> VerifyResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/verify", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func oauthTokenRequest(provider: String, request: OAuthTokenRequest) async throws -> OAuthTokenResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/oauth/token/\(provider)", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func getLoginStatus(userId: String) async throws -> LoginStatusResponse {
        let endpoint = "user/\(userId)/login-status"
        guard let request = createURLRequest(endpoint: endpoint, method: "GET") else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: request)
    }
    
    public func register(request: RegisterRequest) async throws -> RegisterResponse {
        guard let urlRequest = createURLRequest(endpoint: "app/register", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func updateTermsAccepted(userId: String, request: UpdateTermsAcceptedRequest) async throws -> UpdateTermsAcceptedResponse {
        guard let urlRequest = createURLRequest(endpoint: "user/\(userId)/terms-accepted", method: "PATCH", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        return try await performRequest(request: urlRequest)
    }
    
    public func getAccountList(request: GetAccountListRequest) async throws -> GetAccountListResponse {
        let queryString = request.toQueryParams()
        guard let url = URL(string: baseUrl + "account?\(queryString)") else {
            throw WepinError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        setDefaultHeaders(request: &urlRequest)
        return try await performRequest(request: urlRequest)
    }
    
    public func getAccountBalance(accountId: String) async throws -> GetAccountBalanceResponse {
        guard let url = URL(string: baseUrl + "accountbalance/\(accountId)/balance") else {
            throw WepinError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        setDefaultHeaders(request: &urlRequest)
        return try await performRequest(request: urlRequest)
    }
    
    public func getNFTList(request: GetNFTListRequest) async throws -> GetNFTListResponse {
        let queryString = request.toQueryParams()
        guard let url = URL(string: baseUrl + "nft?\(queryString)") else {
            throw WepinError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        setDefaultHeaders(request: &urlRequest)
        return try await performRequest(request: urlRequest)
    }
    
    public func refreshNFTList(request: GetNFTListRequest) async throws -> GetNFTListResponse {
        let queryString = request.toQueryParams()
        guard let url = URL(string: baseUrl + "nft/refresh?\(queryString)") else {
            throw WepinError.invalidRequest
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        setDefaultHeaders(request: &urlRequest)
        return try await performRequest(request: urlRequest)
    }
}
