//
//  File.swift
//  
//
//  Created by linhey on 2023/7/22.
//

import Foundation

public struct QdrantPointsVectors {
    
    public let client: QdrantClient
    public let collection: String

}

public extension QdrantPointsVectors {
    
    func update(at collectionName: String,
                       parameters: UpdateVectors,
                       wait: Bool? = nil,
                       ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .put
        request.path = "/collections/\(collectionName)/points/vectors"
        
        var queryItems = [(name: String, value: String)]()
        if let wait = wait {
            queryItems.append((name: "wait", value: String(wait)))
        }
        if let ordering = ordering {
            queryItems.append((name: "ordering", value: ordering.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func delete(at collectionName: String,
                       parameters: DeleteVectors,
                       wait: Bool? = nil,
                       ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collectionName)/points/vectors/delete"
        
        var queryItems = [(name: String, value: String)]()
        if let wait = wait {
            queryItems.append((name: "wait", value: String(wait)))
        }
        if let ordering = ordering {
            queryItems.append((name: "ordering", value: ordering.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
}
