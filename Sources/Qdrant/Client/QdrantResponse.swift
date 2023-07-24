//
//  File.swift
//  
//
//  Created by linhey on 2023/7/22.
//

import Foundation
import HTTPTypes

public struct QdrantResponse {
    public let data: Data
    public let response: HTTPResponse
    public init(data: Data, response: HTTPResponse) {
        self.data = data
        self.response = response
    }
}
