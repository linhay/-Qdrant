//
//  File.swift
//  
//
//  Created by linhey on 2023/7/23.
//

import Foundation

public struct QdrantPointsPayload {
    
    public let client: QdrantClient
    public let collection: String

}

public extension QdrantPointsPayload {
    
    func set(at collectionName: String,
             parameters: SetPayload,
             wait: Bool? = nil,
             ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collectionName)/points/payload"
        
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
    
    func overwrite(at collectionName: String,
                   parameters: SetPayload,
                   wait: Bool? = nil,
                   ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .put
        request.path = "/collections/\(collectionName)/points/payload"
        
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
                payload: DeletePayload,
                wait: Bool? = nil,
                ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collectionName)/points/payload/delete"
        
        var queryItems = [(name: String, value: String)]()
        if let wait = wait {
            queryItems.append((name: "wait", value: String(wait)))
        }
        if let ordering = ordering {
            queryItems.append((name: "ordering", value: ordering.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(payload)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func clear(at collectionName: String,
               selector: PointsSelector,
               wait: Bool? = nil,
               ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collectionName)/points/payload/clear"
        
        var queryItems = [(name: String, value: String)]()
        if let wait = wait {
            queryItems.append((name: "wait", value: String(wait)))
        }
        if let ordering = ordering {
            queryItems.append((name: "ordering", value: ordering.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(selector)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
}
