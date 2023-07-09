//
//  File.swift
//
//
//  Created by linhey on 2023/6/13.
//

import Foundation
import STJSON

public struct QTCollections {
    
    public let client: QTClientProtocol
    
    public init(client: QTClientProtocol) {
        self.client = client
    }
    
}

public extension QTCollections {
    
    func list() async throws -> [CollectionDescription] {
        let data = try await client.get(path: "collections")
        return try QTResponse<CollectionsResponse>(from: data).result.collections
    }
    
    func info(name: String) async throws -> CollectionInfo {
        let data = try await client.get(path: "collections/" + name)
        return try QTResponse<CollectionInfo>(from: data).result
    }

    func create(name: String, payload: CreateCollection) async throws -> Bool {
        let data = try await client.put(path: "collections/" + name, parameters: payload.dictionaryValue)
        return try QTResponse<Bool>(from: data).result
    }
//
//    func update(name: String, payload: CreatePayload = .init()) async throws -> Bool {
//        let data = try await client.put(path: "collections/" + name, parameters: Qdrant.dictionary(payload))
//        return try JSONDecoder().decode(Response<Bool>.self, from: data).result
//    }
    
    func delete(name: String) async throws -> Bool {
        let data = try await client.delete(path: "collections/" + name)
        return try QTResponse<Bool>(from: data).result
    }

}
