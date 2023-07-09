//
//  File.swift
//  
//
//  Created by linhey on 2023/6/28.
//

import Foundation

public struct QTPoints {
    
    public let collection: String
    public let client: QTClientProtocol
    
    public init(collection: String, client: QTClientProtocol) {
        self.collection = collection
        self.client = client
    }
    
}

public extension QTPoints {
    
    func info(id: Int, consistency: ReadConsistency? = nil) async throws -> ScoredPoint {
        var queries = [String]()
        if let consistency = consistency {
            queries.append(consistency.query)
        }
        let data = try await client.get(path: "collections/\(collection)/points/\(id)?\(queries.joined(separator: "&"))")
        return try QTResponse<ScoredPoint>(from: data).result
    }
    
    func upsert(_ params: QTPointsList,
                wait: Bool? = nil,
                ordering: QTWriteOrdering? = nil) async throws -> UpdateResult {
        var queries = [String]()
        if let wait = wait {
            queries.append(wait ? "wait=true" : "wait=false")
        }
        
        if let ordering = ordering {
            queries.append("ordering=\(ordering.rawValue)")
        }
        
        let data = try await client.put(path: "collections/\(collection)/points?\(queries.joined(separator: "&"))",
                                        parameters: params.dictionaryValue)
        return try QTResponse<UpdateResult>(from: data).result
    }
    
    func search(_ params: SearchRequest, consistency: ReadConsistency? = nil) async throws -> [ScoredPoint] {
        var queries = [String]()
        if let consistency = consistency {
            queries.append(consistency.query)
        }
        let data = try await client.post(path: "collections/\(collection)/points/search?\(queries.joined(separator: "&"))",
                                         parameters: params.dictionaryValue)
        return try QTResponse<[ScoredPoint]>(from: data).result
    }
    
}

