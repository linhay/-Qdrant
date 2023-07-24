//
//  File.swift
//  
//
//  Created by linhey on 2023/7/22.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation
import Qdrant

@available(macOS 13.0, *)
struct Client: QTClient {
    
    var request: HTTPTypes.HTTPRequest {
        var request = HTTPRequest(url: URL(string: "http://localhost:6333")!)
        request.headerFields[.contentType] = "application/json"
        return request
    }
    
    func data(for request: HTTPTypes.HTTPRequest) async throws -> QdrantResponse {
        var name = request.path?.replacingOccurrences(of: "/", with: "_") ?? ""
        name += "_"
        name += request.method.rawValue.lowercased()

        let response = try await URLSession.shared.data(for: request)
        try write(data: response.0, name: name + "_data")
        return .init(data: response.0, response: response.1)
    }
    
    func upload(for request: HTTPTypes.HTTPRequest, from bodyData: Data) async throws -> QdrantResponse {
        var name = request.path?.replacingOccurrences(of: "/", with: "_") ?? ""
        name += "_"
        name += request.method.rawValue.lowercased()
        
        try write(data: bodyData, name: name + "_body")
        let response = try await URLSession.shared.upload(for: request, from: bodyData)
        try write(data: response.0, name: name + "_data")
        return .init(data: response.0, response: response.1)
    }
    
    func write(data: Data, name: String) throws {
        let url = URL(filePath: "/Users/linhey/Desktop/qdrant-test/\(name).json")
        if FileManager.default.fileExists(atPath: url.absoluteString) {
            try FileManager.default.removeItem(at: url)
        }
        try data.write(to: url)
    }
    
}
