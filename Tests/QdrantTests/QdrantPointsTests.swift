//
//  File.swift
//  
//
//  Created by linhey on 2023/7/22.
//

import XCTest
import Qdrant

@available(macOS 13.0, *)
final class QdrantPointsTests: XCTestCase {
    
    let points = QdrantPoints(client: Client(), collection: "test_collection")
    
}

@available(macOS 13.0, *)
 extension QdrantPointsTests {
    
    func test_point() async throws {
        try await points.point(id: 1)
    }
    
    func test_points() async throws  {
        try await points.points(parameters: .init(ids: [1], with_payload: .all, with_vector: .all))
    }
    
    func test_upsert() async throws {
       try await points.upsert(parameters: .list(.init(points: [
        .init(id: 1, vector: [0.05, 0.61, 0.76, 0.74], payload: ["city": "Berlin"]),
        .init(id: 2, vector: [0.19, 0.81, 0.75, 0.11], payload: ["city": ["Berlin", "London"]]),
        .init(id: 3, vector: [0.36, 0.55, 0.47, 0.94], payload: ["city": ["Berlin", "Moscow"]]),
        .init(id: 4, vector: [0.18, 0.01, 0.85, 0.80], payload: ["city": ["London", "Moscow"]]),
        .init(id: 5, vector: [0.24, 0.18, 0.22, 0.44], payload: ["count": [0]]),
        .init(id: 6, vector: [0.35, 0.08, 0.11, 0.44])
    ])))
    }
    
    func test_delete() async throws {
        try await points.delete(parameters: .init(points: [1, 2, 3, 4, 5]))
    }
    
    func test_scroll() async throws {
        try await points.scroll(parameters: .init(with_vector: .all))
    }

    func  test_search() async throws {
        try await points.search(parameters: .init(vector: .init([0.2,0.1,0.9,0.7]),
                                                  limit: 5,
                                                  with_payload: .all,
                                                  with_vector: .all))
    }

//    func test_recommend() async throws {
//        try await points.recommend(parameters: )
//    }
//
//    func count(at collectionName: String,
//               parameters: CountRequest) async throws -> CountResult {
//        var request = client.request
//        request.method = .post
//        request.path = "/collections/\(collectionName)/points/count"
//
//        let request_body = try client.encoder.encode(parameters)
//        let response = try await client.upload(for: request, from: request_body)
//        return try QTModelResponsor(decoder: client.decoder, response: response).model
//    }
//
//    func searchBatch(at collectionName: String,
//                     parameters: SearchRequestBatch,
//                     consistency: ReadConsistency? = nil) async throws -> [[ScoredPoint]] {
//        var request = client.request
//        request.method = .post
//        request.path = "/collections/\(collectionName)/points/search/batch"
//
//        var queryItems = [(name: String, value: String)]()
//        if let consistency = consistency {
//            queryItems.append((name: "consistency", value: consistency.rawValue))
//        }
//        request = client.add(queries: queryItems, to: request)
//
//        let request_body = try client.encoder.encode(parameters)
//        let response = try await client.upload(for: request, from: request_body)
//        return try QTModelResponsor(decoder: client.decoder, response: response).model
//    }
//
//    func searchGroups(collectionName: String,
//                      parameters: SearchGroupsRequest,
//                      consistency: ReadConsistency? = nil) async throws -> GroupsResult {
//        var request = client.request
//        request.method = .post
//        request.path = "/collections/\(collectionName)/points/search/groups"
//
//        var queryItems = [(name: String, value: String)]()
//        if let consistency = consistency {
//            queryItems = [("consistency", consistency.rawValue)]
//        }
//        request = client.add(queries: queryItems, to: request)
//
//        let request_body = try client.encoder.encode(parameters)
//        let response = try await client.upload(for: request, from: request_body)
//        return try QTModelResponsor(decoder: client.decoder, response: response).model
//    }
//
//    func recommendBatch(at collectionName: String,
//                        parameters: RecommendRequestBatch,
//                        consistency: ReadConsistency? = nil) async throws -> [[ScoredPoint]] {
//        var request = client.request
//        request.method = .post
//        request.path = "/collections/\(collectionName)/points/recommend/batch"
//
//        var queryItems = [(name: String, value: String)]()
//        if let consistency = consistency {
//            queryItems = [("consistency", consistency.rawValue)]
//        }
//        request = client.add(queries: queryItems, to: request)
//
//        let request_body = try client.encoder.encode(parameters)
//        let response = try await client.upload(for: request, from: request_body)
//        return try QTModelResponsor(decoder: client.decoder, response: response).model
//    }
//
//    func recommendGroups(at collectionName: String,
//                         parameters: RecommendGroupsRequest,
//                         consistency: ReadConsistency? = nil) async throws -> GroupsResult {
//        var request = client.request
//        request.method = .post
//        request.path = "/collections/\(collectionName)/points/recommend/groups"
//
//        var queryItems = [(name: String, value: String)]()
//        if let consistency = consistency {
//            queryItems = [("consistency", consistency.rawValue)]
//        }
//        request = client.add(queries: queryItems, to: request)
//
//        let request_body = try client.encoder.encode(parameters)
//        let response = try await client.upload(for: request, from: request_body)
//        return try QTModelResponsor(decoder: client.decoder, response: response).model
//    }
    
}
