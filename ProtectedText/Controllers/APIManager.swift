//
//  APIManager.swift
//  ProtectedText
//
//  Created by Rishi Singh on 26/06/25.
//

import Foundation
//#if os(iOS)
//import UIKit
//#endif

class APIManager {
    static let baseURL = "https://www.protectedtext.com"
    static private let session = URLSession.shared
    
    // MARK: - Private Methods
    
    static private func createRequest(
        endPoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        contentType: String? = nil,
        accept: String? = nil
    ) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endPoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue(contentType ?? "application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.addValue(customUserAgent(), forHTTPHeaderField: "User-Agent")
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    static private func performRequest<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> (T, Data) {
        do {
            let (data, _) = try await session.data(for: request)
            
            do {
                let decoder = JSONDecoder()
                let stringData = String(data: data, encoding: .utf8)
                
                // Rate limit exceeded if getting empty response
                guard let stringData = stringData, !stringData.isEmpty else {
                    throw APIError.rateLimitExceeded
                }
                
                return (try decoder.decode(T.self, from: data), data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    static func saveData(endPoint: String, initHashContent: String, currentHashContent: String, encryptedContent: String) async throws -> SaveDataResponse {
        let bodyParameters: [String: String] = [
            "initHashContent": initHashContent,
            "currentHashContent": currentHashContent,
            "encryptedContent": encryptedContent,
            "action": "save",
        ]
//        let body = bodyParameters.queryParameters.data(using: .utf8, allowLossyConversion: true)
        let body = bodyParameters.urlEncodedString.data(using: .utf8)
        
        guard let request = createRequest(endPoint: endPoint, method: .POST, body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request, responseType: SaveDataResponse.self).0
    }
    
    static func getData(endPoint: String) async throws -> SiteData {
        guard let request = createRequest(endPoint: "\(endPoint)?action=json", method: .GET) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request, responseType: SiteData.self).0
    }
    
    static func deleteData(endPoint: String, initHashContent: String) async throws -> EmptyResponse {
        let bodyParameters: [String: String] = [
            "initHashContent": initHashContent,
            "action": "delete",
        ]
        let body = bodyParameters.urlEncodedString.data(using: .utf8)
        guard let request = createRequest(endPoint: endPoint, method: .POST, body: body) else {
            throw APIError.invalidURL
        }
        return try await performRequest(request, responseType: EmptyResponse.self).0
    }
    
    static private func customUserAgent() -> String {
//        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "UnknownApp"
//        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
//
//        #if os(iOS)
//        let osVersion = UIDevice.current.systemVersion
//        let device = UIDevice.current.model
//        #elseif os(macOS)
//        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
//        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
//        let device = "Mac"
//        #else
//        let osVersionString = "UnknownOS"
//        let device = "UnknownDevice"
//        #endif
//
//        #if os(iOS)
//        return "\(appName)/\(appVersion) (iOS \(osVersion); \(device)) GCDHTTPRequest"
//        #elseif os(macOS)
//        return "\(appName)/\(appVersion) (macOS \(osVersionString); \(device)) GCDHTTPRequest"
//        #else
//        return "\(appName)/\(appVersion) (\(device)) GCDHTTPRequest"
//        #endif
        
        return "RapidAPI/4.3.4 (Macintosh; OS X/15.5.0) GCDHTTPRequest"
    }

}

struct SaveDataResponse: Codable {
    let status: String
    let message: String?
    let expectedDBVersion: Int?
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

struct EmptyResponse: Codable {}

enum APIError: Error, LocalizedError {
    case invalidURL
    case rateLimitExceeded
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait before making another request."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

extension Dictionary where Key == String, Value == String {
    var urlEncodedString: String {
        // allowedCharacters set is RFC 3986-compliant
        // We will not use .alphanumeric because that does not include (-_.~) these four characters
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return self.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? ""
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

