//
//  WepinLoginStorage.swift
//  Pods
//
//  Created by iotrust on 3/19/25.
//
import WepinCommon
import WepinNetwork
import WepinStorage

func setWepinUser(request: WepinLoginResult, response: LoginResponse) {
    WepinStorage.shared.deleteAllStorage()
    WepinStorage.shared.setStorage(key: "firebase:wepin", data: StorageDataType.FirebaseWepin(idToken: request.token.idToken, refreshToken: request.token.refreshToken, provider: request.provider.rawValue))
    WepinStorage.shared.setStorage(key: "wepin:connectUser", data: StorageDataType.WepinToken(accessToken: response.token.access, refreshToken: response.token.refresh))
    WepinStorage.shared.setStorage(key: "user_id", data: response.userInfo.userId)
    WepinStorage.shared.setStorage(key: "user_status", data: StorageDataType.UserStatus(loginStatus: response.loginStatus, pinRequired: (response.loginStatus == "registerRequired" ? response.pinRequired : false)))
    
    if (response.loginStatus != "pinRequired" && response.walletId != nil) {
        WepinStorage.shared.setStorage(key: "wallet_id", data: response.walletId)
        WepinStorage.shared.setStorage(key: "user_info",
                                       data: StorageDataType.UserInfo(
                                        status: "success",
                                        userInfo: StorageDataType.UserInfoDetails(
                                            userId: response.userInfo.userId,
                                            email: response.userInfo.email,
                                            provider: request.provider.rawValue,
                                            use2FA: (response.userInfo.use2FA >= 2)
                                        ),
                                        walletId: response.walletId)
        )
    } else {
        let userInfo = StorageDataType.UserInfo(status: "success",
                                                userInfo: StorageDataType.UserInfoDetails(
                                                    userId: response.userInfo.userId,
                                                    email: response.userInfo.email,
                                                    provider: request.provider.rawValue,
                                                    use2FA: (response.userInfo.use2FA >= 2)
                                                ))
        WepinStorage.shared.setStorage(key: "user_info", data: userInfo)
    }
    WepinStorage.shared.setStorage(key: "oauth_provider_pending", data: request.provider.rawValue)
}

func setFirebaseUser(loginResult: WepinLoginResult) {
    WepinStorage.shared.deleteAllStorage()
    WepinStorage.shared.setStorage(key: "firebase:wepin",
                                   data: StorageDataType.FirebaseWepin(
                                    idToken: loginResult.token.idToken,
                                    refreshToken: loginResult.token.refreshToken,
                                    provider: loginResult.provider.rawValue)
    )
}

func getWepinUser() -> WepinUser? {
    if let userInfo = WepinStorage.shared.getStorage(key: "user_info", type: StorageDataType.UserInfo.self),
       let wepinToken = WepinStorage.shared.getStorage(key: "wepin:connectUser", type: StorageDataType.WepinToken.self),
       let userStatus = WepinStorage.shared.getStorage(key: "user_status", type: StorageDataType.UserStatus.self) {
        let walletId = WepinStorage.shared.getStorage(key: "wallet_id")
        
        if walletId == nil {
            return WepinUser(
                status: "success",
                userInfo: WepinUser.UserInfo(
                    userId: userInfo.userInfo.userId,
                    email: userInfo.userInfo.email,
                    provider: userInfo.userInfo.provider,
                    use2FA: userInfo.userInfo.use2FA
                ),
                walletId: nil,
                userStatus: WepinUser.WepinUserStatus(
                    loginStatus: userStatus.loginStatus,
                    pinRequired: userStatus.pinRequired
                ),
                token: WepinUser.WepinToken(
                    access: wepinToken.accessToken, refresh: wepinToken.refreshToken
                ))
        }
        return WepinUser(status: "success",
                         userInfo: WepinUser.UserInfo(
                            userId: userInfo.userInfo.userId,
                            email: userInfo.userInfo.email,
                            provider: userInfo.userInfo.provider,
                            use2FA: userInfo.userInfo.use2FA
                         ),
                         walletId: walletId as? String,
                         userStatus: WepinUser.WepinUserStatus(
                            loginStatus: userStatus.loginStatus,
                            pinRequired: userStatus.pinRequired
                         ),
                         token: WepinUser.WepinToken(
                            access: wepinToken.accessToken,
                            refresh: wepinToken.refreshToken
                         )
        )
    }
    return nil
}
