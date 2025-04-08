//
//  NetworkError.swift
//  Pods
//
//  Created by iotrust on 3/18/25.
//

public enum NetworkError: Error {
    case invalidURL
    case noData
    case parsingError
    case failedResponse(message: String)
}
