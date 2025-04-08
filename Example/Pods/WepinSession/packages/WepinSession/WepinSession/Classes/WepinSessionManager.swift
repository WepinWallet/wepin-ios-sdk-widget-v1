import WepinCommon
import WepinStorage
import WepinNetwork

public class WepinSessionManager {
    public static let shared = WepinSessionManager()
    // MARK: - Properties
    private var _initialized = false
    var lifecycle: WepinLifeCycle = .notInitialized
    
    public func initialize(appId: String, sdkType: String) {
        if (_initialized) { return }
        WepinStorage.shared.initManager(appId: appId, sdkType: sdkType)
        _initialized = true
    }
    
    public func finalize() {
        _initialized = false
    }
    
    public func isInitialized() -> Bool {
        return _initialized
    }
    
    
    // MARK: - Public Methods
    public func checkLoginStatusAndGetLifeCycle() async -> WepinLifeCycle {
        _ = await checkSession()
        return lifecycle
    }
    
    
    public func clearSession() {
        WepinNetwork.shared.clearAuthToken()
        WepinStorage.shared.deleteAllStorage()
    }

    
    func checkSession() async -> StorageDataType.WepinToken? {
        guard let token = getWepinToken(),
              let userId = WepinStorage.shared.getStorage(key: "user_id") as? String else {
            handleSessionClear()
            return nil
        }
        
        WepinNetwork.shared.setAuthToken(access: token.accessToken, refresh: token.refreshToken)

        do {
            let newAccessToken = try await WepinNetwork.shared.getAccessToken(userId: userId)
            // 저장된 토큰 업데이트
            let updatedToken = StorageDataType.WepinToken(accessToken: newAccessToken.token, refreshToken: token.refreshToken)
            WepinStorage.shared.setStorage(key: "wepin:connectUser", data: updatedToken)
            WepinNetwork.shared.setAuthToken(access: newAccessToken.token, refresh: token.refreshToken)

            let loginStatus = try await WepinNetwork.shared.getLoginStatus(userId: userId)
                let userStatus = StorageDataType.UserStatus(
                    loginStatus: loginStatus.loginStatus,
                    pinRequired: loginStatus.pinRequired ?? false
                )
                WepinStorage.shared.setStorage(key: "user_status", data: userStatus)

                lifecycle = (loginStatus.loginStatus == "complete") ? .login : .loginBeforeRegister

            return updatedToken

        } catch {
            print("❌ checkSession error: \(error.localizedDescription)")
            handleSessionClear()
            return nil
        }
    }
    
    public func checkExistFirebaseLoginSession() async  -> Bool {
        do {
            let token = WepinStorage.shared.getStorage<StorageDataType.FirebaseWepin>(key: "firebase:wepin") as? StorageDataType.FirebaseWepin
            
            if token == nil {
                handleSessionClear()
                return false
            }
            
            var response = try await WepinFirebaseNetwork.shared.getRefreshIdToken(GetRefreshIdTokenRequest(refreshToken: token!.refreshToken))
            
            var newToken = StorageDataType.FirebaseWepin(idToken: response.idToken, refreshToken: token!.refreshToken, provider: token!.provider)
            
            WepinStorage.shared.setStorage(key: "firebase:wepin", data: newToken)
            
            return true
        } catch {
            handleSessionClear()
            return false
        }
    }

    private func handleSessionClear() {
        WepinNetwork.shared.clearAuthToken()
        WepinStorage.shared.deleteStorage(key: "wepin:connectUser")
        lifecycle = .initialized
    }
    
    public func getWepinUser() -> WepinUser? {
        guard
            let token = getWepinToken(),
            let userInfo = getUserInfo(),
            let userStatus = getUserStatus()
        else {
            return nil
        }

        return WepinUser(
            status: userInfo.status,
            userInfo: WepinUser.UserInfo(
                userId: userInfo.userInfo.userId,
                email: userInfo.userInfo.email,
                provider: userInfo.userInfo.provider,
                use2FA: userInfo.userInfo.use2FA
            ),
            walletId: userInfo.walletId,
            userStatus: WepinUser.WepinUserStatus(
                loginStatus: userStatus.loginStatus,
                pinRequired: userStatus.pinRequired
            ),
            token: WepinUser.WepinToken(
                access: token.accessToken,
                refresh: token.refreshToken
            )
        )
    }
    

    public func getWepinToken() -> StorageDataType.WepinToken? {
        return WepinStorage.shared.getStorage(key: "wepin:connectUser", type: StorageDataType.WepinToken.self)
    }

    public func getUserInfo() -> StorageDataType.UserInfo? {
        return WepinStorage.shared.getStorage(key: "user_info", type: StorageDataType.UserInfo.self)
    }

    public func getUserStatus() -> StorageDataType.UserStatus? {
        return WepinStorage.shared.getStorage(key: "user_status", type: StorageDataType.UserStatus.self)
    }
}
