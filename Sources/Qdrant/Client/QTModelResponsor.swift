//
//  File.swift
//  
//
//  Created by linhey on 2023/7/21.
//

import Foundation
import HTTPTypes

struct QTModelResponsor<Model: Codable> {
    
    public let decoder: JSONDecoder
    public let response: QdrantResponse
    
    public var model: Model {
        get throws {
            try decoder.decode(QTResponse<Model>.self, from: response.data).result
        }
    }

}
