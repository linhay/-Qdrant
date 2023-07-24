import Foundation
import HTTPTypes
import AnyCodable

public struct QTResponse<Result: Codable>: Codable {
    let time: Double
    let status: Status
    let result: Result
    
    public enum Status: Codable {
        
        public struct Error: Codable  {
            let error: String
        }
        
        case ok
        case error(String)
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let msg = try? container.decode(String.self) {
                if msg == "ok" {
                    self = .ok
                } else {
                    self = .error(msg)
                }
            } else {
                self = try .error(Error(from: decoder).error)
            }
        }
        
    }
    
}

public struct CollectionsResponse: Codable {
    let collections: [CollectionDescription]
}

public struct CollectionDescription: Codable {
    let name: String
}

public struct CollectionInfo: Codable {
    public let status: CollectionStatus
    public let optimizer_status: OptimizersStatus
    public let vectors_count: Int
    public let indexed_vectors_count: Int
    public let points_count: Int
    public let segments_count: Int
    public let config: CollectionConfig?
    public let payload_schema: [String: PayloadIndexInfo]
}

public enum CollectionStatus: String, Codable {
    case green
    case yellow
    case red
}

public enum OptimizersStatus: Codable {
    case ok
    case error(String)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .ok
        } else if let value = try? container.decode([String: String].self), let error = value["error"] {
            self = .error(error)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid OptimizersStatus")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .ok:
            try container.encode("ok")
        case .error(let error):
            try container.encode(["error": error])
        }
    }
}

public struct CollectionConfig: Codable {
    public let hnsw_config: HnswConfig
    public let optimizer_config: OptimizersConfig
    public let params: CollectionParams
    public let wal_config: WalConfig
    public let quantization_config: QuantizationConfig?
}

public struct CollectionParams: Codable {
    public let vectors: VectorsConfig
    public let shard_number: Int
    public let replication_factor: Int
    public let write_consistency_factor: Int
    public let on_disk_payload: Bool
}

public enum Distance: String, Codable {
    case cosine = "Cosine"
    case euclid = "Euclid"
    case dot = "Dot"
}

public struct HnswConfigDiff: Codable {
    public let m: Int?
    public let ef_construct: Int?
    public let full_scan_threshold: Int?
    public let max_indexing_threads: Int?
    public let on_disk: Bool?
    public let payload_m: Int?
}

public struct ScalarQuantization: Codable {
    public let scalar: ScalarQuantizationConfig
}

public struct VectorParams: Codable {
    
    public let size: Int
    public let distance: Distance
    public let hnsw_config: HnswConfigDiff?
    public let quantization_config: QuantizationConfig?
    public let on_disk: Bool?
    
    public init(size: Int,
                distance: Distance,
                hnsw_config: HnswConfigDiff? = nil,
                quantization_config: QuantizationConfig? = nil,
                on_disk: Bool? = nil) {
        self.size = size
        self.distance = distance
        self.hnsw_config = hnsw_config
        self.quantization_config = quantization_config
        self.on_disk = on_disk
    }
    
}

public enum VectorsConfig: Codable {
    
    public struct Object: Codable {
        public let object: VectorParams
    }
    
    case vectorParams(VectorParams)
    case object(Object)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(VectorParams.self) {
            self = .vectorParams(value)
        } else {
            self = try .object(.init(from: decoder))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .vectorParams(let vectorParams):
            try container.encode(vectorParams)
        case .object(let object):
            try container.encode(object)
        }
    }
    
}

public enum QuantizationConfig: Codable {
    
    case scalar(ScalarQuantization)
    case product(ProductQuantization)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let scalarQuantization = try? container.decode(ScalarQuantization.self) {
            self = .scalar(scalarQuantization)
        } else if let productQuantization = try? container.decode(ProductQuantization.self) {
            self = .product(productQuantization)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid QuantizationConfig")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .scalar(let scalarQuantization):
            try container.encode(scalarQuantization)
        case .product(let productQuantization):
            try container.encode(productQuantization)
        }
    }
}

public struct ScalarQuantizationConfig: Codable {
    public let type: ScalarType
    public let quantile: Double?
    public let alwaysRam: Bool?
}

public enum ScalarType: String, Codable {
    case int8
}

public struct ProductQuantization: Codable {
    public let product: ProductQuantizationConfig
}

public struct ProductQuantizationConfig: Codable {
    public let compression: CompressionRatio
    public let alwaysRam: Bool?
}

public enum CompressionRatio: String, Codable {
    case x4
    case x8
    case x16
    case x32
    case x64
}

public struct HnswConfig: Codable {
    public let m: Int
    public let ef_construct: Int
    public let full_scan_threshold: Int
    public let max_indexing_threads: Int
    public let on_disk: Bool?
    public let payload_m: Int?
}

public struct OptimizersConfig: Codable {
    public let deleted_threshold: Double
    public let vacuum_min_vector_number: Int
    public let default_segment_number: Int
    public let max_segment_size: Int?
    public let memmap_threshold: Int?
    public let indexing_threshold: Int?
    public let flush_interval_sec: Int
    public let max_optimization_threads: Int
}

public struct WalConfig: Codable {
    let wal_capacity_mb: Int
    let wal_segments_ahead: Int
}

public struct PayloadIndexInfo: Codable {
    let data_type: PayloadSchemaType
    let params: PayloadSchemaParams?
    let points: Int
}

enum PayloadSchemaType: String, Codable {
    case keyword
    case integer
    case float
    case geo
    case text
}

enum PayloadSchemaParams: Codable {
    case text(TextIndexParams)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let textIndexParams = try? container.decode(TextIndexParams.self) {
            self = .text(textIndexParams)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid PayloadSchemaParams")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let textIndexParams):
            try container.encode(textIndexParams)
        }
    }
}

public struct TextIndexParams: Codable {
    let type: TextIndexType
    let tokenizer: TokenizerType
    let minTokenLen: Int?
    let maxTokenLen: Int?
    let lowercase: Bool?
}

enum TextIndexType: String, Codable {
    case text = "text"
}


enum TokenizerType: String, Codable {
    case prefix
    case whitespace
    case word
}

public struct PointRequest: Codable {
    
    public let ids: [ExtendedPointId]
    public let with_payload: WithPayloadInterface?
    public let with_vector: WithVector
    
    public init(ids: [ExtendedPointId],
                with_payload: WithPayloadInterface? = nil,
                with_vector: WithVector) {
        self.ids = ids
        self.with_payload = with_payload
        self.with_vector = with_vector
    }
    
    
    public init(ids: [Int],
                with_payload: WithPayloadInterface? = nil,
                with_vector: WithVector) {
        self.init(ids: ids.map({ .integer(UInt64($0))}),
                  with_payload: with_payload,
                  with_vector: with_vector)
    }
}

public enum ExtendedPointId: Codable, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
   
    case integer(UInt64)
    case string(String)
    
    public init(integerLiteral value: UInt64) {
        self = .integer(value)
    }
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    
    var string: String {
        switch self {
        case .integer(let uInt64):
            return uInt64.description
        case .string(let string):
            return string
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(UInt64.self) {
            self = .integer(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ExtendedPointId value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let intValue):
            try container.encode(intValue)
        case .string(let stringValue):
            try container.encode(stringValue)
        }
    }
}

public enum WithPayloadInterface: Codable {
    case all
    case none
    case fields([String])
    case selector(PayloadSelector)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .all : .none
        } else if let fieldsValue = try? container.decode([String].self) {
            self = .fields(fieldsValue)
        } else if let selectorValue = try? container.decode(PayloadSelector.self) {
            self = .selector(selectorValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid WithPayloadInterface value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .all:
            try container.encode(true)
        case .none:
            try container.encode(false)
        case .fields(let fieldsValue):
            try container.encode(fieldsValue)
        case .selector(let selectorValue):
            try container.encode(selectorValue)
        }
    }
}


public struct PayloadSelector: Codable {
    public let include: [String]?
    public let exclude: [String]?
}

public struct PayloadSelectorInclude: Codable {
    let include: [String]
}

public struct PayloadSelectorExclude: Codable {
    let exclude: [String]
}

public enum WithVector: Codable {
    
    case all
    case none
    case vectors([String])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .all : .none
        } else if let vectorsValue = try? container.decode([String].self) {
            self = .vectors(vectorsValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid WithVector value")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .all:
            try container.encode(true)
        case .none:
            try container.encode(false)
        case .vectors(let vectorsValue):
            try container.encode(vectorsValue)
        }
    }
}

public struct Record: Codable {
    public let id: ExtendedPointId
    public let payload: Payload?
    public let vector: VectorStruct?
}

public typealias Payload = [String: AnyCodable]

public enum VectorStruct: Codable {
    case array([Decimal])
    case object([String: [Decimal]])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let array = try? container.decode([Decimal].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: [Decimal]].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(Self.self,
                                             DecodingError.Context(codingPath: decoder.codingPath,
                                                                   debugDescription: "Invalid vector type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

public struct SearchRequest: Codable {
    public var vector: NamedVectorStruct
    public var filter: Filter?
    public var params: SearchParams?
    public var limit: UInt
    public var offset: UInt
    public var with_payload: WithPayloadInterface?
    public var with_vector: WithVector?
    public var score_threshold: Float?
    
    public init(vector: NamedVectorStruct,
                filter: Filter? = nil,
                params: SearchParams? = nil,
                limit: UInt,
                offset: UInt = 0,
                with_payload: WithPayloadInterface? = nil,
                with_vector: WithVector? = nil,
                score_threshold: Float? = nil) {
        self.vector = vector
        self.filter = filter
        self.params = params
        self.limit = limit
        self.offset = offset
        self.with_payload = with_payload
        self.with_vector = with_vector
        self.score_threshold = score_threshold
    }
}

public struct NamedVectorStruct: Codable {
    
    public enum VectorType: Codable {
        case array([Decimal])
        case named(NamedVector)
    }
    
    public let vector: VectorType
    
    public enum CodingKeys: CodingKey {
        case vector
    }
    
    public init(_ vector: [Decimal]) {
        self.vector = .array(vector)
    }
    
    public init(_ vector: NamedVector) {
        self.vector = .named(vector)
    }
    
    public init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([Decimal].self) {
            vector = .array(array)
            return
        }
        
        if let namedVector = try? decoder.container(keyedBy: CodingKeys.self).decode(NamedVector.self,
                                                                                     forKey: .vector) {
            vector = .named(namedVector)
            return
        }

        throw DecodingError.typeMismatch(VectorType.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid vector type"))
    }
    
    public func encode(to encoder: Encoder) throws {
        switch vector {
        case .array(let array):
            var container = encoder.singleValueContainer()
            try container.encode(array)
        case .named(let vector):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(vector, forKey: .vector)
        }
    }
}

public struct NamedVector: Codable {
    let name: String
    let vector: [Decimal]
}


public enum Condition: Codable {
    case field(FieldCondition)
    case isEmpty(IsEmptyCondition)
    case isNull(IsNullCondition)
    case hasId(HasIdCondition)
    case nested(NestedCondition)
    case filter(Filter)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let fieldCondition = try? container.decode(FieldCondition.self) {
            self = .field(fieldCondition)
        } else if let isEmptyCondition = try? container.decode(IsEmptyCondition.self) {
            self = .isEmpty(isEmptyCondition)
        } else if let isNullCondition = try? container.decode(IsNullCondition.self) {
            self = .isNull(isNullCondition)
        } else if let hasIdCondition = try? container.decode(HasIdCondition.self) {
            self = .hasId(hasIdCondition)
        } else if let nestedCondition = try? container.decode(NestedCondition.self) {
            self = .nested(nestedCondition)
        } else if let filter = try? container.decode(Filter.self) {
            self = .filter(filter)
        } else {
            throw DecodingError.typeMismatch(Condition.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid condition type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .field(let fieldCondition):
            try container.encode(fieldCondition)
        case .isEmpty(let isEmptyCondition):
            try container.encode(isEmptyCondition)
        case .isNull(let isNullCondition):
            try container.encode(isNullCondition)
        case .hasId(let hasIdCondition):
            try container.encode(hasIdCondition)
        case .nested(let nestedCondition):
            try container.encode(nestedCondition)
        case .filter(let filter):
            try container.encode(filter)
        }
    }
}

public struct FieldCondition: Codable {
    public let key: String
    public let match: Match?
    public let range: Range?
    public let geoBoundingBox: GeoBoundingBox?
    public let geoRadius: GeoRadius?
    public let valuesCount: ValuesCount?
}

public struct Match: Codable {
    public let description: String
    public let anyOf: [MatchVariant]
}

public enum MatchVariant: Codable {
    case matchValue(MatchValue)
    case matchText(MatchText)
    case matchAny(MatchAny)
    case matchExcept(MatchExcept)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(MatchValue.self) {
            self = .matchValue(value)
        } else if let text = try? container.decode(MatchText.self) {
            self = .matchText(text)
        } else if let any = try? container.decode(MatchAny.self) {
            self = .matchAny(any)
        } else if let except = try? container.decode(MatchExcept.self) {
            self = .matchExcept(except)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid MatchVariant")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .matchValue(let value):
            try container.encode(value)
        case .matchText(let text):
            try container.encode(text)
        case .matchAny(let any):
            try container.encode(any)
        case .matchExcept(let except):
            try container.encode(except)
        }
    }
}

public struct MatchValue: Codable {
    public let description: String
    public let value: ValueVariants
}

public enum ValueVariants: Codable {
    case string(String)
    case integer(Int64)
    case boolean(Bool)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let integer = try? container.decode(Int64.self) {
            self = .integer(integer)
        } else if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ValueVariants")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .integer(let integer):
            try container.encode(integer)
        case .boolean(let boolean):
            try container.encode(boolean)
        }
    }
}

public struct MatchText: Codable {
    let text: String
}

public struct MatchAny: Codable {
    let any: AnyVariants
}

public struct MatchExcept: Codable {
    let except: AnyVariants
}

enum AnyVariants: Codable {
    case string(String)
    case integer(Int64)
    case boolean(Bool)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let integer = try? container.decode(Int64.self) {
            self = .integer(integer)
        } else if let boolean = try? container.decode(Bool.self) {
            self = .boolean(boolean)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid AnyVariants")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try container.encode(string)
        case .integer(let integer):
            try container.encode(integer)
        case .boolean(let boolean):
            try container.encode(boolean)
        }
    }
}

public struct Range: Codable {
    let lt: Double?
    let gt: Double?
    let gte: Double?
    let lte: Double?
}

public struct GeoBoundingBox: Codable {
    let top_left: GeoPoint
    let bottom_right: GeoPoint
}

public struct GeoPoint: Codable {
    let lon: Double
    let lat: Double
}

public struct GeoRadius: Codable {
    let center: GeoPoint
    let radius: Double
}

public struct ValuesCount: Codable {
    let lt: UInt?
    let gt: UInt?
    let gte: UInt?
    let lte: UInt?
}

public struct IsEmptyCondition: Codable {
    let is_empty: PayloadField
    
}

public struct PayloadField: Codable {
    let key: String
}

public struct IsNullCondition: Codable {
    let is_null: PayloadField
}

public struct HasIdCondition: Codable {
    let has_id: [ExtendedPointId]
}

public struct NestedCondition: Codable {
    let nested: Nested
}

public struct Nested: Codable {
    let key: String
    let filter: Filter
}

public struct Filter: Codable {
    public let should: [Condition]?
    public let must: [Condition]?
    public let mustNot: [Condition]?
}

public struct SearchParams: Codable {
    let hnsw_ef: Int?
    let exact: Bool
    let quantization: QuantizationSearchParams?
}

public struct QuantizationSearchParams: Codable {
    let ignore: Bool
    let rescore: Bool
    let oversampling: Double?
}

public struct ScoredPoint: Codable {
    let id: ExtendedPointId
    let version: UInt64
    let score: Float
    let payload: Payload?
    let vector: VectorStruct?
}

public struct UpdateResult: Codable {
    public let operation_id: UInt64
    public let status: UpdateStatus
}

public enum UpdateStatus: String, Codable {
    case acknowledged
    case completed
}

public struct RecommendRequest: Codable {
    public var positive: [ExtendedPointId]
    public var negative: [ExtendedPointId]
    public var filter: Filter?
    public var params: SearchParams?
    public var limit: UInt
    public var offset: UInt
    public var with_payload: WithPayloadInterface?
    public var with_vector: WithVector?
    public var score_threshold: Float?
    public var using: UsingVector?
    public var lookup_from: LookupLocation?
}

public typealias UsingVector = String

public struct LookupLocation: Codable {
    public let collection: String
    public let vector: String?
}

public struct ScrollRequest: Codable {
    public let offset: ExtendedPointId?
    public let limit: UInt?
    public let filter: Filter?
    public let with_payload: WithPayloadInterface?
    public let with_vector: WithVector
    
    public init(offset: ExtendedPointId? = nil,
         limit: UInt? = nil,
         filter: Filter? = nil,
         with_payload: WithPayloadInterface? = nil,
         with_vector: WithVector) {
        self.offset = offset
        self.limit = limit
        self.filter = filter
        self.with_payload = with_payload
        self.with_vector = with_vector
    }
}

public struct ScrollResult: Codable {
    let points: [Record]
    let next_page_offset: ExtendedPointId?
}

public struct CreateCollection: Codable {
    
    public let vectors: VectorsConfig
    public let shard_number: UInt32?
    public let replication_factor: UInt32?
    public let write_consistency_factor: UInt32?
    public let on_disk_payload: Bool?
    public let hnsw_config: HnswConfigDiff?
    public let wal_config: WalConfigDiff?
    public let optimizers_config: OptimizersConfigDiff?
    public let init_from: InitFrom?
    public let quantization_config: QuantizationConfig?
    
    public init(vectors: VectorsConfig,
                shard_number: UInt32? = nil,
                replication_factor: UInt32? = nil,
                write_consistency_factor: UInt32? = nil,
                on_disk_payload: Bool? = nil,
                hnsw_config: HnswConfigDiff? = nil,
                wal_config: WalConfigDiff? = nil,
                optimizers_config: OptimizersConfigDiff? = nil,
                init_from: InitFrom? = nil,
                quantization_config: QuantizationConfig? = nil) {
        self.vectors = vectors
        self.shard_number = shard_number
        self.replication_factor = replication_factor
        self.write_consistency_factor = write_consistency_factor
        self.on_disk_payload = on_disk_payload
        self.hnsw_config = hnsw_config
        self.wal_config = wal_config
        self.optimizers_config = optimizers_config
        self.init_from = init_from
        self.quantization_config = quantization_config
    }
    
}

public struct WalConfigDiff: Codable {
    public let wal_capacity_mb: UInt
    public let wal_segments_ahead: UInt
}

public struct OptimizersConfigDiff: Codable {
    
    public var deleted_threshold: Double?
    public var vacuum_min_vector_number: UInt?
    public var default_segment_number: UInt?
    public var max_segment_size: UInt?
    public var memmap_threshold: UInt?
    public var indexing_threshold: UInt?
    public var flush_interval_sec: UInt64?
    public var max_optimization_threads: UInt?
    
    public init(deleted_threshold: Double? = nil,
                vacuum_min_vector_number: UInt? = nil,
                default_segment_number: UInt? = nil,
                max_segment_size: UInt? = nil,
                memmap_threshold: UInt? = nil,
                indexing_threshold: UInt? = nil,
                flush_interval_sec: UInt64? = nil,
                max_optimization_threads: UInt? = nil) {
        self.deleted_threshold = deleted_threshold
        self.vacuum_min_vector_number = vacuum_min_vector_number
        self.default_segment_number = default_segment_number
        self.max_segment_size = max_segment_size
        self.memmap_threshold = memmap_threshold
        self.indexing_threshold = indexing_threshold
        self.flush_interval_sec = flush_interval_sec
        self.max_optimization_threads = max_optimization_threads
    }
    
}

public struct InitFrom: Codable {
    public let collection: String
}

public struct UpdateCollection: Codable {
    public var optimizers_config: OptimizersConfigDiff?
    public var params: CollectionParamsDiff?
    
    public init(optimizers_config: OptimizersConfigDiff? = nil,
                params: CollectionParamsDiff? = nil) {
        self.optimizers_config = optimizers_config
        self.params = params
    }
}

public struct CollectionParamsDiff: Codable {
    public var replication_factor: Int?
    public var write_consistency_factor: Int?
    public init(replication_factor: Int? = nil,
                write_consistency_factor: Int? = nil) {
        self.replication_factor = replication_factor
        self.write_consistency_factor = write_consistency_factor
    }
}

public struct ChangeAliasesOperation: Codable {
    let actions: [AliasOperations]
}

enum AliasOperations: Codable {
    case createAlias(CreateAliasOperation)
    case deleteAlias(DeleteAliasOperation)
    case renameAlias(RenameAliasOperation)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let createAlias = try? container.decode(CreateAliasOperation.self) {
            self = .createAlias(createAlias)
        } else if let deleteAlias = try? container.decode(DeleteAliasOperation.self) {
            self = .deleteAlias(deleteAlias)
        } else if let renameAlias = try? container.decode(RenameAliasOperation.self) {
            self = .renameAlias(renameAlias)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid alias operation")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .createAlias(let createAlias):
            try container.encode(createAlias)
        case .deleteAlias(let deleteAlias):
            try container.encode(deleteAlias)
        case .renameAlias(let renameAlias):
            try container.encode(renameAlias)
        }
    }
}

public struct CreateAliasOperation: Codable {
    let createAlias: CreateAlias
}

public struct CreateAlias: Codable {
    let collection_name: String
    let alias_name: String
}

public struct DeleteAliasOperation: Codable {
    let deleteAlias: DeleteAlias
}

public struct DeleteAlias: Codable {
    let aliasName: String
}

public struct RenameAliasOperation: Codable {
    let renameAlias: RenameAlias
}

public struct RenameAlias: Codable {
    let old_alias_name: String
    let new_alias_name: String
}

public struct CreateFieldIndex: Codable {
    let field_name: String
    let field_schema: PayloadFieldSchema?
}

enum PayloadFieldSchema: Codable {
    case payloadSchemaType(PayloadSchemaType)
    case payloadSchemaParams(PayloadSchemaParams)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let schemaType = try? container.decode(PayloadSchemaType.self) {
            self = .payloadSchemaType(schemaType)
        } else if let schemaParams = try? container.decode(PayloadSchemaParams.self) {
            self = .payloadSchemaParams(schemaParams)
        } else {
            throw DecodingError.typeMismatch(PayloadFieldSchema.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid payload field schema"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .payloadSchemaType(let schemaType):
            try container.encode(schemaType)
        case .payloadSchemaParams(let schemaParams):
            try container.encode(schemaParams)
        }
    }
}

public struct PointsSelector: Codable {
    
    public let points: [ExtendedPointId]?
    public let filter: Filter?
    
    public init(points: [ExtendedPointId]) {
        self.points = points
        self.filter = nil
    }

    public init(filter: Filter?) {
        self.points = nil
        self.filter = filter
    }

}

public enum PointInsertOperations: Codable {
    case batch(PointsBatch)
    case list(PointsList)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let pointsBatch = try? container.decode(PointsBatch.self) {
            self = .batch(pointsBatch)
        } else if let pointsList = try? container.decode(PointsList.self) {
            self = .list(pointsList)
        } else {
            throw DecodingError.typeMismatch(PointInsertOperations.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid point insert operations"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .batch(let pointsBatch):
            try container.encode(pointsBatch)
        case .list(let pointsList):
            try container.encode(pointsList)
        }
    }
}

public enum BatchVectorStruct: Codable {
    case array([[Float]])
    case object([String: [[Float]]])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([[Float]].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: [[Float]]].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(BatchVectorStruct.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid batch vector public struct"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

public struct PointStruct: Codable {
    public let id: ExtendedPointId
    public let vector: VectorStruct
    public let payload: Payload?
    
    public init(id: ExtendedPointId,
                vector: VectorStruct,
                payload: Payload? = nil) {
        self.id = id
        self.vector = vector
        self.payload = payload
    }
    
    public init(id: Int,
                vector: [Decimal],
                payload: Payload? = nil) {
        self.init(id: .integer(UInt64(id)), vector: .array(vector), payload: payload)
    }
}

public struct Batch: Codable {
    public let ids: [ExtendedPointId]
    public let vectors: BatchVectorStruct
    public let payloads: [Payload?]?
}

public struct PointsBatch: Codable {
    public let batch: Batch
    public init(batch: Batch) {
        self.batch = batch
    }
}

public struct PointsList: Codable {
    public let points: [PointStruct]
    public init(points: [PointStruct]) {
        self.points = points
    }
}

public struct SetPayload: Codable {
    public let payload: Payload
    public let points: [ExtendedPointId]?
    public let filter: Filter?
}

public struct DeletePayload: Codable {
    let keys: [String]
    let points: [ExtendedPointId]?
    let filter: Filter?
}

public struct DisabledClusterStatus: Codable {
    let status: String
}

public struct EnabledClusterStatus: Codable {
    let status: String
    let peerId: UInt64
    let peers: [String: PeerInfo]
    let raftInfo: RaftInfo
    let consensusThreadStatus: ConsensusThreadStatus
    let messageSendFailures: [String: MessageSendErrors]
}

enum ClusterStatus: Codable {
    case disabled(DisabledClusterStatus)
    case enabled(EnabledClusterStatus)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let disabledStatus = try? container.decode(DisabledClusterStatus.self) {
            self = .disabled(disabledStatus)
        } else if let enabledStatus = try? container.decode(EnabledClusterStatus.self) {
            self = .enabled(enabledStatus)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid cluster status")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .disabled(let disabledStatus):
            try container.encode(disabledStatus)
        case .enabled(let enabledStatus):
            try container.encode(enabledStatus)
        }
    }
}

public struct PeerInfo: Codable {
    let uri: String
}

public struct RaftInfo: Codable {
    let term: UInt64
    let commit: UInt64
    let pending_operations: UInt
    let leader: UInt64?
    let role: StateRole?
    let is_voter: Bool
}

enum StateRole: String, Codable {
    case follower = "Follower"
    case candidate = "Candidate"
    case leader = "Leader"
    case preCandidate = "PreCandidate"
}

public struct ConsensusThreadStatus: Codable {
    let consensus_thread_status: ConsensusThreadStatusValue
    let last_update: Date?
    let err: String?
}

enum ConsensusThreadStatusValue: String, Codable {
    case working = "working"
    case stopped = "stopped"
    case stoppedWithError = "stopped_with_err"
}

public struct MessageSendErrors: Codable {
    let count: UInt
    let latestError: String?
}

public struct SnapshotDescription: Codable {
    let name: String
    let creationTime: PartialDateTime?
    let size: UInt64
}

public struct CountRequest: Codable {
    let filter: Filter?
    let exact: Bool
    
    init(filter: Filter? = nil, exact: Bool = true) {
        self.filter = filter
        self.exact = exact
    }
}

public struct CountResult: Codable {
    let count: UInt
}

public struct CollectionClusterInfo: Codable {
    let peer_id: UInt64
    let shard_count: UInt
    let local_shards: [LocalShardInfo]
    let remote_shards: [RemoteShardInfo]
    let shard_transfers: [ShardTransferInfo]
}

public struct LocalShardInfo: Codable {
    let shard_id: UInt32
    let points_count: UInt
    let state: ReplicaState
}

enum ReplicaState: String, Codable {
    case active = "Active"
    case dead = "Dead"
    case partial = "Partial"
    case initializing = "Initializing"
    case listener = "Listener"
}

public struct RemoteShardInfo: Codable {
    let shard_id: UInt32
    let peer_id: UInt64
    let state: ReplicaState
}

public struct ShardTransferInfo: Codable {
    let shardID: UInt32
    let from: UInt64
    let to: UInt64
    let sync: Bool
}

public struct TelemetryData: Codable {
    let id: String
    let app: AppBuildTelemetry
    let collections: CollectionsTelemetry
    let cluster: ClusterTelemetry
    let requests: RequestsTelemetry
}

public struct AppBuildTelemetry: Codable {
    let name: String
    let version: String
    let features: AppFeaturesTelemetry?
    let system: RunningEnvironmentTelemetry?
    let startup: Date
}

public struct AppFeaturesTelemetry: Codable {
    let debug: Bool
    let web_feature: Bool
    let service_debug_feature: Bool
    let recovery_mode: Bool
}

public struct RunningEnvironmentTelemetry: Codable {
    let distribution: String?
    let distribution_version: String?
    let is_docker: Bool
    let cores: UInt?
    let ram_size: UInt?
    let disk_size: UInt?
    let cpu_flags: String
}

typealias PartialDateTime = String


public struct CollectionsTelemetry: Codable {
    let numberOfCollections: Int
    let collections: [CollectionTelemetryEnum]?
}

enum CollectionTelemetryEnum: Codable {
    case collectionTelemetry(CollectionTelemetry)
    case collectionsAggregatedTelemetry(CollectionsAggregatedTelemetry)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(CollectionTelemetry.self) {
            self = .collectionTelemetry(value)
        } else if let value = try? container.decode(CollectionsAggregatedTelemetry.self) {
            self = .collectionsAggregatedTelemetry(value)
        } else {
            throw DecodingError.typeMismatch(CollectionTelemetryEnum.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid enum value"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .collectionTelemetry(let value):
            try container.encode(value)
        case .collectionsAggregatedTelemetry(let value):
            try container.encode(value)
        }
    }
}

public struct CollectionTelemetry: Codable {
    let id: String
    let initTimeMs: UInt64
    let config: CollectionConfig
    let shards: [ReplicaSetTelemetry]
    let transfers: [ShardTransferInfo]
}

public struct ReplicaSetTelemetry: Codable {
    let id: UInt32
    let local: LocalShardTelemetry?
    let remote: [RemoteShardTelemetry]
    let replicateStates: [String: ReplicaState]
}

public struct LocalShardTelemetry: Codable {
    let variantName: String?
    let segments: [SegmentTelemetry]
    let optimizations: OptimizerTelemetry
}

public struct SegmentTelemetry: Codable {
    let info: SegmentInfo
    let config: SegmentConfig
    let vectorIndexSearches: [VectorIndexSearchesTelemetry]
    let payloadFieldIndices: [PayloadIndexTelemetry]
}

public struct SegmentInfo: Codable {
    let segmentType: SegmentType
    let numVectors: Int
    let numPoints: Int
    let numDeletedVectors: Int
    let ramUsageBytes: Int
    let diskUsageBytes: Int
    let isAppendable: Bool
    let indexSchema: [String: PayloadIndexInfo]
}

enum SegmentType: String, Codable {
    case plain
    case indexed
    case special
}

public struct SegmentConfig: Codable {
    let vectorData: [String: VectorDataConfig]
    let payloadStorageType: PayloadStorageType
}

public struct VectorDataConfig: Codable {
    let size: Int
    let distance: Distance
    let storageType: VectorStorageType
    let index: Indexes
    let quantizationConfig: QuantizationConfig?
}

enum VectorStorageType: String, Codable {
    case memory = "Memory"
    case mmap = "Mmap"
    case chunkedMmap = "ChunkedMmap"
}

public struct Indexes: Codable {
    public let indexType: IndexType
    
    public enum CodingKeys: String, CodingKey {
        case indexType = "oneOf"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let indexTypeArray = try? container.decode([IndexType].self, forKey: .indexType) {
            guard let indexType = indexTypeArray.first else {
                throw DecodingError.dataCorruptedError(forKey: .indexType, in: container, debugDescription: "Invalid index type")
            }
            self.indexType = indexType
        } else if let indexTypeObject = try? container.decode(IndexType.self, forKey: .indexType) {
            self.indexType = indexTypeObject
        } else {
            throw DecodingError.dataCorruptedError(forKey: .indexType, in: container, debugDescription: "Invalid index type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let indexType = indexType as? [IndexType] {
            try container.encode(indexType, forKey: .indexType)
        } else if let indexType = indexType as? IndexType {
            try container.encode(indexType, forKey: .indexType)
        } else {
            throw EncodingError.invalidValue(indexType, EncodingError.Context(codingPath: [CodingKeys.indexType], debugDescription: "Invalid index type"))
        }
    }
}

public enum IndexType: Codable {
    case plain(PlainIndex)
    case hnsw(HnswIndex)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let plainIndex = try? container.decode(PlainIndex.self) {
            self = .plain(plainIndex)
        } else if let hnswIndex = try? container.decode(HnswIndex.self) {
            self = .hnsw(hnswIndex)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid index type")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .plain(let plainIndex):
            try container.encode(plainIndex)
        case .hnsw(let hnswIndex):
            try container.encode(hnswIndex)
        }
    }
}

public struct PlainIndex: Codable {
    let type: String
    let options: Options
    
    public struct Options: Codable {}
}

public struct HnswIndex: Codable {
    let type: String
    let options: HnswConfig
    
    public struct HnswConfig: Codable {}
}

public struct PayloadStorageType: Codable {
    let type: String
}

public struct VectorIndexSearchesTelemetry: Codable {
    let indexName: String?
    let unfilteredPlain: OperationDurationStatistics
    let unfilteredHnsw: OperationDurationStatistics
    let filteredPlain: OperationDurationStatistics
    let filteredSmallCardinality: OperationDurationStatistics
    let filteredLargeCardinality: OperationDurationStatistics
    let filteredExact: OperationDurationStatistics
    let unfilteredExact: OperationDurationStatistics
}

public struct OperationDurationStatistics: Codable {
    let count: Int
    let failCount: Int
    let avgDurationMicros: Double?
    let minDurationMicros: Double?
    let maxDurationMicros: Double?
    let lastResponded: String?
}

public struct PayloadIndexTelemetry: Codable {
    let field_name: String?
    let points_values_count: Int
    let points_count: Int
    let histogram_bucket_size: Int?
}

public struct OptimizerTelemetry: Codable {
    let status: OptimizersStatus
    let optimizations: OperationDurationStatistics
}

public struct RemoteShardTelemetry: Codable {
    let shardId: Int
    let peerId: Int?
    let searches: OperationDurationStatistics
    let updates: OperationDurationStatistics
}

public struct CollectionsAggregatedTelemetry: Codable {
    let vectors: Int
    let optimizers_status: OptimizersStatus
    let params: CollectionParams
}

public struct ClusterTelemetry: Codable {
    let enabled: Bool
    let status: ClusterStatusTelemetry?
    let config: ClusterConfigTelemetry?
}

public struct ClusterStatusTelemetry: Codable {
    let number_of_peers: Int
    let term: Int
    let commit: Int
    let pending_operations: Int
    let role: StateRole?
    let is_voter: Bool
    let peer_id: Int?
    let consensus_thread_status: ConsensusThreadStatus
}

public struct ClusterConfigTelemetry: Codable {
    let grpc_timeout_ms: Int
    let p2p: P2pConfigTelemetry
    let consensus: ConsensusConfigTelemetry
}

public struct P2pConfigTelemetry: Codable {
    let connection_pool_size: Int
}

public struct ConsensusConfigTelemetry: Codable {
    let max_message_queue_size: Int
    let tick_period_ms: Int
    let bootstrap_timeout_sec: Int
}

public struct RequestsTelemetry: Codable {
    let rest: WebApiTelemetry
    let grpc: GrpcTelemetry
}

public struct WebApiTelemetry: Codable {
    let responses: [String: [String: OperationDurationStatistics]]
}

public struct GrpcTelemetry: Codable {
    let responses: [String: OperationDurationStatistics]
}

enum ClusterOperations: Codable {
    case moveShard(MoveShardOperation)
    case replicateShard(ReplicateShardOperation)
    case abortTransfer(AbortTransferOperation)
    case dropReplica(DropReplicaOperation)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let moveShardOperation = try? container.decode(MoveShardOperation.self) {
            self = .moveShard(moveShardOperation)
        } else if let replicateShardOperation = try? container.decode(ReplicateShardOperation.self) {
            self = .replicateShard(replicateShardOperation)
        } else if let abortTransferOperation = try? container.decode(AbortTransferOperation.self) {
            self = .abortTransfer(abortTransferOperation)
        } else if let dropReplicaOperation = try? container.decode(DropReplicaOperation.self) {
            self = .dropReplica(dropReplicaOperation)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ClusterOperations")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .moveShard(let moveShardOperation):
            try container.encode(moveShardOperation)
        case .replicateShard(let replicateShardOperation):
            try container.encode(replicateShardOperation)
        case .abortTransfer(let abortTransferOperation):
            try container.encode(abortTransferOperation)
        case .dropReplica(let dropReplicaOperation):
            try container.encode(dropReplicaOperation)
        }
    }
}

public struct MoveShardOperation: Codable {
    let moveShard: MoveShard
}

public struct MoveShard: Codable {
    let shard_id: Int
    let to_peer_id: Int
    let from_peer_id: Int
}

public struct ReplicateShardOperation: Codable {
    let replicateShard: MoveShard
}

public struct AbortTransferOperation: Codable {
    let abortTransfer: MoveShard
}

public struct DropReplicaOperation: Codable {
    let dropReplica: Replica
}

public struct Replica: Codable {
    let shardId: UInt32
    let peerId: UInt64
}

public struct SearchRequestBatch: Codable {
    let searches: [SearchRequest]
}

public struct RecommendRequestBatch: Codable {
    let searches: [RecommendRequest]
}

public struct LocksOption: Codable {
    let errorMessage: String?
    let write: Bool
}

public struct SnapshotRecover: Codable {
    let location: String
    let priority: SnapshotPriority?
}

enum SnapshotPriority: String, Codable {
    case snapshot
    case replica
}

public struct CollectionsAliasesResponse: Codable {
    let aliases: [AliasDescription]
}

public struct AliasDescription: Codable {
    let aliasName: String
    let collectionName: String
}

public enum WriteOrdering: String, Codable {
    case weak
    case medium
    case strong
}

public enum ReadConsistency: Codable {
    
    case integer(UInt)
    case type(ReadConsistencyType)
    
    public init(from decoder: Decoder) throws {
        if let intValue = try? decoder.singleValueContainer().decode(UInt.self) {
            self = .integer(intValue)
        } else {
            self = .type(try decoder.singleValueContainer().decode(ReadConsistencyType.self))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let intValue):
            try container.encode(intValue)
        case .type(let typeValue):
            try container.encode(typeValue)
        }
    }
    
    var rawValue: String {
        switch self {
        case .integer(let uInt):
            return uInt.description
        case .type(let readConsistencyType):
            return readConsistencyType.rawValue
        }
    }
}

public enum ReadConsistencyType: String, Codable {
    case majority
    case quorum
    case all
}

public struct UpdateVectors: Codable {
    let points: [PointVectors]
}

public struct PointVectors: Codable {
    let id: ExtendedPointId
    let vector: VectorStruct
}

public struct DeleteVectors: Codable {
    let points: [ExtendedPointId]?
    let filter: Filter?
    let vector: [String]
}

public struct PointGroup: Codable {
    let hits: [ScoredPoint]
    let id: GroupId
    let lookup: Record?
}

enum GroupId: Codable {
    case string(String)
    case integer(UInt64)
    case int64(Int64)
    
    init(from decoder: Decoder) throws {
        if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? decoder.singleValueContainer().decode(UInt64.self) {
            self = .integer(intValue)
        } else {
            self = .int64(try decoder.singleValueContainer().decode(Int64.self))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let stringValue):
            try container.encode(stringValue)
        case .integer(let intValue):
            try container.encode(intValue)
        case .int64(let int64Value):
            try container.encode(int64Value)
        }
    }
}

public struct WithLookup: Codable {
    let collection: String
    let with_payload: WithPayloadInterface?
    let with_vectors: WithVector?
}

public struct WithLookupInterface: Codable {
    // TODO: Add properties for WithLookupInterface
}

public struct SearchGroupsRequest: Codable {
    let vector: NamedVectorStruct
    let filter: Filter?
    let params: SearchParams?
    let with_payload: WithPayloadInterface?
    let with_vector: WithVector?
    let score_threshold: Float?
    let group_by: String
    let group_size: Int
    let limit: Int
    let with_lookup: WithLookupInterface?
}

public struct RecommendGroupsRequest: Codable {
    let positive: [ExtendedPointId]
    let negative: [ExtendedPointId]
    let filter: Filter?
    let params: SearchParams?
    let with_payload: WithPayloadInterface?
    let with_vector: WithVector?
    let score_threshold: Float?
    let using: UsingVector?
    let lookup_from: LookupLocation?
    let group_by: String
    let group_size: Int
    let limit: Int
    let with_lookup: WithLookupInterface?
}

public struct GroupsResult: Codable {
    let groups: [PointGroup]
}
