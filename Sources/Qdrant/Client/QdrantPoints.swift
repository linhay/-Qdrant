//
//  File.swift
//  
//
//  Created by linhey on 2023/7/22.
//

import Foundation
import HTTPTypes

public struct QdrantPoints {
    
    public let client: QdrantClient
    public let collection: String
    public let vectors: QdrantPointsVectors
    public let payload: QdrantPointsPayload
    
    public init(client: QdrantClient, collection: String) {
        self.client = client
        self.collection = collection
        vectors = .init(client: client, collection: collection)
        payload = .init(client: client, collection: collection)
    }
    
}

public extension QdrantPoints {
    
    func point(id: ExtendedPointId,
               consistency: ReadConsistency? = nil) async throws -> Record {
        var request = client.request
        request.method = .get
        request.path = "/collections/\(collection)/points/\(id.string)"
        
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems.append((name: "consistency", value: consistency.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        let response = try await client.data(for: request)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func points(parameters: PointRequest,
                consistency: ReadConsistency? = nil) async throws -> [Record] {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points"
        let request_body = try client.encoder.encode(parameters)
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems.append((name: "consistency", value: consistency.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func upsert(parameters: PointInsertOperations,
                wait: Bool? = nil,
                ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .put
        request.path = "/collections/\(collection)/points"
        
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
    
    func delete(parameters: PointsSelector,
                wait: Bool? = nil,
                ordering: WriteOrdering? = nil) async throws -> UpdateResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/delete"
        let request_body = try client.encoder.encode(parameters)
        
        var queryItems = [(name: String, value: String)]()
        if let wait = wait {
            queryItems.append((name: "wait", value: String(wait)))
        }
        if let ordering = ordering {
            queryItems.append((name: "ordering", value: ordering.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func scroll(parameters: ScrollRequest,
                consistency: ReadConsistency? = nil) async throws -> ScrollResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/scroll"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems.append((name: "consistency", value: consistency.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func search(parameters: SearchRequest,
                consistency: ReadConsistency? = nil) async throws -> [ScoredPoint] {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/search"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems.append((name: "consistency", value: consistency.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func recommend(parameters: RecommendRequest,
                   consistency: ReadConsistency? = nil) async throws -> [ScoredPoint] {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/recommend"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems = [("consistency", consistency.rawValue)]
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func count(parameters: CountRequest) async throws -> CountResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/count"
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func searchBatch(parameters: SearchRequestBatch,
                     consistency: ReadConsistency? = nil) async throws -> [[ScoredPoint]] {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/search/batch"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems.append((name: "consistency", value: consistency.rawValue))
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func searchGroups(parameters: SearchGroupsRequest,
                      consistency: ReadConsistency? = nil) async throws -> GroupsResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/search/groups"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems = [("consistency", consistency.rawValue)]
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func recommendBatch(parameters: RecommendRequestBatch,
                        consistency: ReadConsistency? = nil) async throws -> [[ScoredPoint]] {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/recommend/batch"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems = [("consistency", consistency.rawValue)]
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
    func recommendGroups(parameters: RecommendGroupsRequest,
                         consistency: ReadConsistency? = nil) async throws -> GroupsResult {
        var request = client.request
        request.method = .post
        request.path = "/collections/\(collection)/points/recommend/groups"
        
        var queryItems = [(name: String, value: String)]()
        if let consistency = consistency {
            queryItems = [("consistency", consistency.rawValue)]
        }
        request = client.add(queries: queryItems, to: request)
        
        let request_body = try client.encoder.encode(parameters)
        let response = try await client.upload(for: request, from: request_body)
        return try QTModelResponsor(decoder: client.decoder, response: response).model
    }
    
}
