//
//  File.swift
//  
//
//  Created by linhey on 2023/7/21.
//

import Foundation
import HTTPTypes

public struct QdrantCollections {
    
    public let client: QdrantClient
    
    public init(client: QdrantClient) {
        self.client = client
    }
    
}

public extension QdrantCollections {
    
    func delete(_ name: String) async throws -> Bool {
        var request = client.request
        request.method = .delete
        request.path = "/collections/\(name)"
        
        let response = try await client.data(for: request)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func create(name: String, parameters: CreateCollection) async throws -> Bool {
        var request = client.request
        request.method = .put
        request.path = "/collections/\(name)"
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func info(name: String) async throws -> CollectionInfo {
        var request = client.request
        request.method = .get
        request.path = "/collections/\(name)"

        let response = try await client.data(for: request)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func update(name: String, parameters: UpdateCollection) async throws -> Bool {
        var request = client.request
        request.method = .patch
        request.path = "/collections/test_collection"
                
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
}
