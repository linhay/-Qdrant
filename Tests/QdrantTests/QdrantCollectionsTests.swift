import XCTest
import Qdrant

@available(macOS 13.0, *)
final class QdrantCollectionsTests: XCTestCase {
    
    let collections = QdrantCollections(client: Client())
    
    func test_delete() async throws {
        _ = try await collections.delete("test_collection")
    }
    
    func test_create() async throws {
        let parameters: CreateCollection = CreateCollection(vectors: .vectorParams(.init(size: 4, distance: .dot)))
        _ = try await collections.create(name: "test_collection", parameters: parameters)
    }
    
    func test_get() async throws {
        _ = try await collections.info(name: "test_collection")
    }
    
    func test_patch() async throws {
        let parameters: UpdateCollection = .init()
        _ = try await collections.update(name: "test_collection", parameters: parameters)
    }
    
}
