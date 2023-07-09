//
//  File.swift
//  
//
//  Created by linhey on 2023/6/28.
//

import Foundation
import STJSON

public struct QTResponse<T> {
    
    let time: TimeInterval
    let status: QTStatus
    let result: T
    
    public init(from json: JSON) throws where T: JSONEncodableModel {
        self.time   = json["time"].doubleValue
        self.status = try .init(from: json["status"])
        self.result = try .init(from: json["result"])
    }
    
    public init(from json: JSON) throws where T: Decodable {
        self.time   = json["time"].doubleValue
        self.status = try .init(from: json["status"])
        self.result = try T.decode(from: json["result"])
    }
    
    public init(from data: Data) throws where T: JSONEncodableModel {
        try self.init(from: JSON(data: data))
    }
    
    public init(from data: Data) throws where T: Decodable {
        try self.init(from: JSON(data: data))
    }
    
}
