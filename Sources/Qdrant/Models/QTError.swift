//
//  File.swift
//  
//
//  Created by linhey on 2023/6/13.
//

import Foundation

struct QTError: LocalizedError {
    
    static let decode = QTError(.decode)
    static let encode = QTError(.encode)
    static func network(_ msg: String) -> QTError {
        return .init(.network, message: msg)
    }

    enum Kind: String {
        case decode
        case encode
        case network
    }
    
    let kind: Kind
    let message: String
    
    init(_ kind: Kind, message: String = "") {
        self.kind = kind
        self.message = message
    }
    
}
