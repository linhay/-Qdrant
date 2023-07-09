//
//  File.swift
//  
//
//  Created by linhey on 2023/6/13.
//

import Foundation

public protocol QTClientProtocol {

    var baseURL: String { get }
    func get(path: String) async throws -> Data
    func post(path: String, parameters: [String: Any]) async throws -> Data
    func put(path: String, parameters: [String: Any]) async throws -> Data
    func delete(path: String) async throws -> Data

}
