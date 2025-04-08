//
//  Utils.swift
//  Pods
//
//  Created by iotrust on 3/18/25.
//
import Foundation
import BCrypt

func customURLEncode(_ string: String) -> String {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: ":/")
    return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
}

func isFirstEmailUser(errorString: String) -> Bool {
    do {
        let data = errorString.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
        guard let dictionary = jsonObject as? [String: Any] else {
            return false
        }
        
        guard let status = dictionary["status"] as? Int,
              let message = dictionary["message"] as? String else {
            return false
        }
        
        let isStatus400 = (status == 400)
        let isMessageContainsNotExist = message.contains("not exist")
        
        return isStatus400 && isMessageContainsNotExist
    } catch {
        return false
    }
}

func hashPassword(_ password: String) -> String {
    let BCRYPT_SALT = "$2a$10$QCJoWqnN.acrjPIgKYCthu"
    return try! BCrypt.Hash(password, salt: BCRYPT_SALT)
}

func extractScopes(from url: URL) -> [String]? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        return nil
    }

    if let scopeItem = queryItems.first(where: { $0.name == "scope" }),
       let scopeValue = scopeItem.value {
        return scopeValue.components(separatedBy: " ")
    }

    return nil
}

