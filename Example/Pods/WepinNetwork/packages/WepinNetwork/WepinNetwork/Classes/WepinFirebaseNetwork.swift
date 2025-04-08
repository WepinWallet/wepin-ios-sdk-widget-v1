import Foundation
import WepinCommon

public class WepinFirebaseNetwork {
    public static let shared = WepinFirebaseNetwork()
    // MARK: - Properties
    private let firebaseUrl = "https://identitytoolkit.googleapis.com/v1/"
    private var firebaseKey: String?
    private var _initialized: Bool = false
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    
    // MARK: - Initialization
    public func initialize(firebaseKey: String) {
        if _initialized { return }
        self.firebaseKey = firebaseKey
        _initialized = true
    }
    
    public func isInitialize() -> Bool {
        return self._initialized
    }
    
    public func finalize() {
        self.firebaseKey = nil
        self._initialized = false
    }
    
    // MARK: - Network Helpers
    private func createURLRequest(endpoint: String, method: String = "POST", body: [String: Any]? = nil) -> URLRequest? {
        guard let firebaseKey = self.firebaseKey,
              let url = URL(string: firebaseUrl + endpoint + "?key=\(firebaseKey)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        return request
    }
    
    private func performRequest<T: Decodable>(request: URLRequest) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: WepinError.networkError("No data received"))
                    return
                }
                
                do {
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
                    continuation.resume(throwing: WepinError.parsingFailed(decodeError.localizedDescription))
                } catch {
                    continuation.resume(throwing: error)
                }
            }.resume()
        }
    }
    
    // MARK: - Firebase Auth Methods
    public func signInWithCustomToken(_ customToken: String) async throws -> SignInWithCustomTokenSuccess {
        let body: [String: Any] = [
            "token": customToken,
            "returnSecureToken": true
        ]
        guard let request = createURLRequest(endpoint: "accounts:signInWithCustomToken", body: body) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func signInWithEmailPassword(_ request: EmailAndPasswordRequest) async throws -> SignInResponse {
        guard let request = createURLRequest(endpoint: "accounts:signInWithPassword", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func getCurrentUser(_ request: GetCurrentUserRequest) async throws -> GetCurrentUserResponse {
        guard let request = createURLRequest(endpoint: "accounts:lookup", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func getRefreshIdToken(_ request: GetRefreshIdTokenRequest) async throws -> GetRefreshIdTokenSuccess {
        guard let request = createURLRequest(endpoint: "token", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func resetPassword(_ request: ResetPasswordRequest) async throws -> ResetPasswordResponse {
        guard let request = createURLRequest(endpoint: "accounts:resetPassword", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func verifyEmail(_ request: VerifyEmailRequest) async throws -> VerifyEmailResponse {
        guard let request = createURLRequest(endpoint: "accounts:update", body: request.toDictionary()) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func updatePassword(idToken: String, password: String) async throws -> UpdatePasswordSuccess {
        let body: [String: Any] = [
            "idToken": idToken,
            "password": password,
            "returnSecureToken": true
        ]
        
        guard let request = createURLRequest(endpoint: "accounts:update", body: body) else {
            throw WepinError.invalidRequest
        }
        
        return try await performRequest(request: request)
    }
    
    public func logout() async throws -> Bool {
        guard let request = createURLRequest(endpoint: "accounts:logout") else {
            throw WepinError.invalidRequest
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { _, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: true)
            }.resume()
        }
    }
}

// MARK: - Firebase Types
public struct SignInWithCustomTokenSuccess: Codable {
    public let idToken: String
    public let refreshToken: String
    public let expiresIn: String
}

public struct EmailAndPasswordRequest: Codable {
    public let email: String
    public let password: String
    public let returnSecureToken: Bool
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
        self.returnSecureToken = true
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "password": password,
            "returnSecureToken": returnSecureToken
        ]
    }
}

public struct SignInResponse: Codable {
    public let idToken: String
    public let email: String
    public let refreshToken: String
    public let expiresIn: String
    public let localId: String
    public let registered: Bool
}

public struct GetCurrentUserRequest: Codable {
    public let idToken: String
    
    public func toDictionary() -> [String: Any] {
        return ["idToken": idToken]
    }
}

public struct GetCurrentUserResponse: Codable {
    public let users: [FirebaseUser]
}

public struct FirebaseUser: Codable {
    public let localId: String
    public let email: String
    public let emailVerified: Bool
}

public struct GetRefreshIdTokenRequest: Codable {
    public let refreshToken: String
    public let grantType: String
    
    public init(refreshToken: String, grantType: String = "refresh_token") {
        self.refreshToken = refreshToken
        self.grantType = grantType
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "refresh_token": refreshToken,
            "grant_type": grantType
        ]
    }
}

public struct GetRefreshIdTokenSuccess: Codable {
    public let accessToken: String
    public let expiresIn: String
    public let tokenType: String
    public let refreshToken: String
    public let idToken: String
    public let userId: String
    public let projectId: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case userId = "user_id"
        case projectId = "project_id"
    }
}

public struct ResetPasswordRequest: Codable {
    public let oobCode: String
    public let newPassword: String
    
    public init(oobCode: String, newPassword: String) {
        self.oobCode = oobCode
        self.newPassword = newPassword
    }
    
    public func toDictionary() -> [String: Any] {
        return [
            "oobCode": oobCode,
            "newPassword": newPassword
        ]
    }
}

public struct ResetPasswordResponse: Codable {
    public let email: String
    public let requestType: String
}

public struct VerifyEmailRequest: Codable {
    public let idToken: String
    
    public func toDictionary() -> [String: Any] {
        return ["idToken": idToken]
    }
}

public struct VerifyEmailResponse: Codable {
    public let email: String
}

public struct UpdatePasswordSuccess: Codable {
    public let localId: String
    public let email: String
    public let idToken: String
    public let refreshToken: String
    public let expiresIn: String
} 
