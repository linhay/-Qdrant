//
//  File.swift
//  
//
//  Created by linhey on 2023/7/21.
//

import Foundation

public class Qdrant {
    
    public let client: QTClient
    public private(set) lazy var collections = QdrantCollections(client: client)
    
    public init(client: QTClient) {
        self.client = client
    }
    
}
