//
//  File.swift
//  
//
//  Created by linhey on 2023/7/21.
//

import Foundation

public struct Qdrant {
    
    public let client: QdrantClient
    public let collections: QdrantCollections
    
    public init(client: QdrantClient) {
        self.client = client
        self.collections = .init(client: client)
    }
    
    public func points(collection: String) -> QdrantPoints {
        .init(client: client, collection: collection)
    }
    
}
