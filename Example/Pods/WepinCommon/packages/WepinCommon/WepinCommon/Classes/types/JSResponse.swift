//
//  JSResponse.swift
//  Pods
//
//  Created by iotrust on 3/20/25.
//

import Foundation

// JSResponse 구조체
public struct JSResponse: Codable {
    let header: JSResponseHeader
    var body: JSResponseBody

    struct JSResponseHeader: Codable {
        let id: String
        let response_from: String
        let response_to: String
    }

    struct JSResponseBody: Codable {
        let command: String
        var state: String
        var data: AnyCodable? = nil
    }

    // JSResponse의 Builder 패턴
    public class Builder {
        private var response: JSResponse

        public init(id: String, requestFrom: String, command: String, state: String) {
            self.response = JSResponse(
                header: JSResponseHeader(id: id, response_from: "native", response_to: requestFrom),
                body: JSResponseBody(command: command, state: state)
            )
        }

        // ReadyToWidgetBodyData 구조체 정의
        public struct ReadyToWidgetBodyData: Codable {
            let appKey: String
            let appId: String
            let domain: String
            let platform: Int
            let type: String
            let version: String
            let localData: [String: AnyCodable]
            let attributes: WepinAttributeWithProviders?
            public init(appKey: String, appId: String, domain: String, platform: Int, type: String, version: String, localData: [String: AnyCodable], attributes: WepinAttributeWithProviders? = nil) {
                print("ReadyToWidgetBodyData Init")
                self.appKey = appKey
                self.appId = appId
                self.domain = domain
                self.platform = platform
                self.type = type
                self.version = version
                self.localData = localData
                self.attributes = attributes
            }

            public func toDictionary() -> [String: AnyCodable] {
                var dict: [String: AnyCodable] = [
                    "appKey": AnyCodable(appKey),
                    "appId": AnyCodable(appId),
                    "domain": AnyCodable(domain),
                    "platform": AnyCodable(platform),
                    "type": AnyCodable(type),
                    "version": AnyCodable(version),
                    "localDate": AnyCodable(localData)
                ]
                
                // attributes가 nil이 아닐 때만 추가
                if let attributes = attributes {
                    dict["attributes"] = AnyCodable(attributes.toDictionary())
                }
                return dict
            }
        }
        
        public struct SetEmailBodyData: Codable {
            let email: String
            
            public init(email: String) {
                self.email = email
            }
            
            public func toDictionary() -> [String: AnyCodable] {
                let dict: [String: AnyCodable] = [
                    "email": AnyCodable(email)
                ]
                
                return dict
            }
        }
        
        public func setBodyData(parameter: Any) -> Builder {
            if let dict = parameter as? [String: AnyCodable] {
                // parameter가 딕셔너리 형태일 때 처리
                self.response.body.data = AnyCodable(dict)
            } else if let singleValue = parameter as? AnyCodable {
                // parameter가 단일 값일 때 처리
                self.response.body.data = singleValue
            } else {
                // 예상하지 못한 데이터 타입일 경우 처리 (옵션)
                self.response.body.data = AnyCodable("Invalid parameter type")
            }
            
            return self
        }


        public func setErrorBodyData(errMsg: String) -> Builder {
            self.response.body.data = AnyCodable(errMsg)
            return self
        }

        public func build() -> JSResponse {
            return self.response
        }
    }

    // JSON 변환을 위한 함수
    func toJsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("##### [Response] \(jsonString)")
                return jsonString
            }
        } catch {
            print("Error converting to JSON: \(error.localizedDescription)")
        }
        return "Error converting to JSON"
    }
}


public struct AnyCodable: Codable {
    let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let arrayVal = value as? [AnyCodable] {
            try container.encode(arrayVal)
        } else if let dictVal = value as? [String: AnyCodable] {
            try container.encode(dictVal)
        } else {
            try container.encodeNil()
        }
    }
}


extension WepinAttribute {
    func toDictionary() -> [String: AnyCodable] {
        return [
            "defaultLanguage": AnyCodable(defaultLanguage),
            "defualtCurrency": AnyCodable(defaultCurrency)
        ]
    }
}
