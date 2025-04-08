//
//  WepinPresentationContextProvider.swift
//  Pods
//
//  Created by iotrust on 3/18/25.
//

import AuthenticationServices

class WepinPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var window: UIWindow?
    
    init(window: UIWindow?) {
        self.window = window
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return window ?? ASPresentationAnchor()
    }
}
