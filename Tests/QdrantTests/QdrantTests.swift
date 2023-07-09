import XCTest
import Alamofire
import Qdrant

@available(macOS 13.0, *)
struct Client: QTClientProtocol {
    
    let baseURL: String = "http://localhost:6333"
    
    func get(path: String) async throws -> Data {
        let data = try await AF.request(baseURL + "/" + path, method: .get).serializingData().value
        try data.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/get.json"))
        return data
    }
    
    func delete(path: String) async throws -> Data {
        let data = try await AF.request(baseURL + "/" + path, method: .delete).serializingData().value
        try data.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/delete.json"))
        return data
    }

    func post(path: String, parameters: [String: Any]) async throws -> Data {
        let data = try await AF.request(baseURL + "/" + path,
                                        method: .post,
                                        parameters: parameters,
                                        encoding: JSONEncoding.default,
                                        headers: [
                                            .accept("application/json"),
                                            .acceptEncoding("")
                                                 ])
            .cURLDescription(calling: { curl in
                try! curl.data(using: .utf8)?.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/post-curl.json"))
            })
            .serializingData().value
        try data.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/post.json"))
        return data
    }
    
    func put(path: String, parameters: [String: Any]) async throws -> Data {
        let data = try await AF.request(baseURL + "/" + path,
                                        method: .put,
                                        parameters: parameters,
                                        encoding: JSONEncoding.default,
                                        headers: [
                                            .accept("application/json"),
                                            .acceptEncoding("")
                                                 ])
            .cURLDescription(calling: { curl in
                try! curl.data(using: .utf8)?.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/put-curl.json"))
            })
            .serializingData().value
        try data.write(to: URL(filePath: "/Users/linhey/Desktop/qdrant-test/put.json"))
        return data
    }
    
}

final class QdrantTests: XCTestCase {
    
    func testExample() async throws {
        let name = "test_collection"
        let client = Client()
        let collections = QTCollections(client: client)
        let list = try await collections.list()
        if let info = try? await collections.info(name: name) {
            let delete = try await collections.delete(name: name)
        }
        let create = try await collections.create(name: name, payload: .init(vectors: .init(size: 4, distance: .cosine)))
        let info = try? await collections.info(name: name)
        
        let points = QTPoints(collection: name, client: client)
        try await points.upsert(.init(points: [
            .init(id: 1, vector: [0.05, 0.61, 0.76, 0.74], payload: ["city": "Berlin"]),
            .init(id: 2, vector: [0.19, 0.81, 0.75, 0.11], payload: ["city": ["Berlin", "London"]]),
            .init(id: 3, vector: [0.36, 0.55, 0.47, 0.94], payload: ["city": ["Berlin", "Moscow"]]),
            .init(id: 4, vector: [0.18, 0.01, 0.85, 0.80], payload: ["city": ["London", "Moscow"]]),
            .init(id: 5, vector: [0.24, 0.18, 0.22, 0.44], payload: ["count": [0]]),
            .init(id: 6, vector: [0.35, 0.08, 0.11, 0.44])
        ]))
        
        let search1 = try await points.search(.init(vector: .vector([0.2,0.1,0.9,0.7]), limit: 3))
        let search2 = try await points.search(.init(vector: .vector([0.2,0.1,0.9,0.7]),
                                                    filter: .init(should: [.field(.init(key: "city",
                                                                                        match: .value(.init(value: .string("Berlin")))))
                                                                          ]),
                                                    limit: 3,
                                                   with_payload: true,
                                                   with_vector: true))

        let point_info = try await points.info(id: 1)
        
        assert(true)
    }
    
}
