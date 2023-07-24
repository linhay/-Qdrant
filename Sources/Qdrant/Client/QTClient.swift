//
//  File.swift
//  
//
//  Created by linhey on 2023/7/21.
//

import Foundation
import HTTPTypes

public protocol QTClient {
    var request: HTTPRequest { get }
    var encoder: JSONEncoder { get }
    var decoder: JSONDecoder { get }
    
    func data(for request: HTTPRequest) async throws -> QdrantResponse
    func upload(for request: HTTPRequest, from bodyData: Data) async throws -> QdrantResponse
}

public extension QTClient {

    var encoder: JSONEncoder { .init() }
    var decoder: JSONDecoder { .init() }
    
}

public extension QTClient {
    
    func add(queries: [(name: String, value: String)], to request: HTTPRequest) -> HTTPRequest {
        var request = request
        if !queries.isEmpty {
            request.path?.append("?")
            request.path?.append(queries.map({ "\($0.name)=\($0.value)" }).joined(separator: "&"))
        }
        return request
    }
    
}
