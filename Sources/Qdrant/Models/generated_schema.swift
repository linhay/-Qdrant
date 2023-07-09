//
//  File.swift
//
//
//  Created by linhey on 2023/6/13.
//

import Foundation
import STJSON

public enum QTStatus: JSONEncodableModel {
    
    case ok
    case error(String)
    
    public init(from json: JSON) throws {
        if json.string == "ok" {
            self = .ok
        } else if let value = json["error"].string {
            throw QTError.network(value)
        } else {
            throw QTError.decode
        }
    }
    
}

public struct CollectionsResponse: JSONEncodableModel {
    
    public let collections: [CollectionDescription]
    
    public init(from json: JSON) throws {
        self.collections = try json["collections"].arrayValue.map(CollectionDescription.init(from:))
    }
}

public struct CollectionDescription: JSONEncodableModel {
    
    public let name: String
    
    public init(from json: JSON) throws {
        self.name = json["name"].stringValue
    }
}

/** @description Current statistics and configuration of the collection */
public struct CollectionInfo: JSONEncodableModel {
    let status: CollectionStatus
    let optimizer_status: OptimizersStatus
    /**
     * Format: uint
     * @description Number of vectors in collection All vectors in collection are available for querying Calculated as `points_count x vectors_per_point` Where `vectors_per_point` is a number of named vectors in schema
     */
    let vectors_count: UInt
    /**
     * Format: uint
     * @description Number of indexed vectors in the collection. Indexed vectors in large segments are faster to query, as it is stored in vector index (HNSW)
     */
    let indexed_vectors_count: UInt
    /**
     * Format: uint
     * @description Number of points (vectors + payloads) in collection Each point could be accessed by unique id
     */
    let points_count: UInt
    /**
     * Format: uint
     * @description Number of segments in collection. Each segment has independent vector as payload indexes
     */
    let segments_count: UInt
    let config: CollectionConfig
    /** @description Types of stored payload */
    let payload_schema: [String: PayloadIndexInfo]
    
    public init(from json: JSON) throws {
        status = try CollectionStatus.decode(from: json["status"])
        optimizer_status = try .init(from: json["optimizer_status"])
        vectors_count = json["vectors_count"].uIntValue
        indexed_vectors_count = json["indexed_vectors_count"].uIntValue
        points_count = json["points_count"].uIntValue
        segments_count = json["segments_count"].uIntValue
        config = try .init(from: json["config"])
        payload_schema = try json["payload_schema"].dictionaryValue.mapValues(PayloadIndexInfo.init(from:))
    }
}

/**
 * @description Current state of the collection.
 * `Green` - all good.
 * `Yellow` - optimization is running,
 * `Red` - some operations failed and was not recovered
 * @enum {string}
 */
public enum CollectionStatus: String, Codable {
    
    case green
    case yellow
    case red
    
}

///** @description Current state of the collection */
typealias OptimizersStatus = QTStatus

struct CollectionConfig: JSONEncodableModel {
    let params: CollectionParams
    let hnsw_config: HnswConfig
    let optimizer_config: OptimizersConfig
    let wal_config: WalConfig
    /** @default null */
    // let quantization_config: QuantizationConfig?
    
    init(from json: JSON) throws {
        params              = try .init(from: json["params"])
        hnsw_config         = try .init(from: json["hnsw_config"])
        optimizer_config    = try .init(from: json["optimizer_config"])
        wal_config          = try .init(from: json["wal_config"])
        //        quantization_config = try .init(exist: json["quantization_config"])
        if json["quantization_config"].isExists {
            assertionFailure()
        }
    }
}

public struct CollectionParams: JSONEncodableModel {
    let vectors: VectorsConfig
    /**
     * Format: uint32
     * @description Number of shards the collection has
     * @default 1
     */
    let shard_number: UInt32?
    /**
     * Format: uint32
     * @description Number of replicas for each shard
     * @default 1
     */
    let replication_factor: UInt32?
    /**
     * Format: uint32
     * @description Defines how many replicas should apply the operation for us to consider it successful. Increasing this number will make the collection more resilient to inconsistencies, but will also make it fail if not enough replicas are available. Does not have any performance impact.
     * @default 1
     */
    let write_consistency_factor: UInt32?
    /**
     * @description If true - point's payload will not be stored in memory. It will be read from the disk every time it is requested. This setting saves RAM by (slightly) increasing the response time. Note: those payload values that are involved in filtering and are indexed - remain in RAM.
     * @default false
     */
    let on_disk_payload: Bool?
    
    public init(from json: JSON) throws {
        vectors = try .init(from: json["vectors"])
        shard_number = json["shard_number"].uInt32
        replication_factor = json["replication_factor"].uInt32
        write_consistency_factor = json["write_consistency_factor"].uInt32
        on_disk_payload = json["on_disk_payload"].bool
    }
}

/**
 * @description Vector params separator for single and multiple vector modes Single mode:
 *
 * { "size": 128, "distance": "Cosine" }
 *
 * or multiple mode:
 *
 * { "default": { "size": 128, "distance": "Cosine" } }
 */

public struct VectorsConfig: JSONEncodableModel {
    
    public let type: String
    public let additionalProperties: VectorParams
    
    public init(from json: JSON) throws {
        self.type = json["type"].stringValue
        self.additionalProperties = try VectorParams(exist: json["additionalProperties"]) ?? VectorParams(from: json)
    }
    
}

/** @description Params of single vector data storage */
public struct VectorParams: JSONEncodableModel, JSONDecodableModel {
    /**
     * Format: uint64
     * @description Size of a vectors used
     */
    public let size: Int
    public let distance: Distance
    /** @description Custom params for HNSW index. If none - values from collection configuration are used. */
    public let hnsw_config: HnswConfigDiff?
    /** @description Custom params for quantization. If none - values from collection configuration are used. */
    public let quantization_config: QuantizationConfig?
    /** @description If true, vectors are served from disk, improving RAM usage at the cost of latency Default: false */
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
    
    public init(from json: JSON) throws {
        self.size        = json["size"].intValue
        self.distance    = try Distance.decode(from: json["distance"])
        self.hnsw_config = try HnswConfigDiff.decodeIfPresent(from: json["hnsw_config"])
        self.quantization_config = try .init(exist: json["quantization_config"])
        self.on_disk     = json["on_disk"].bool
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["size"] = size
            dict["distance"] = distance.rawValue
            dict["hnsw_config"] = try hnsw_config?.dictionaryValue
            dict["on_disk"] = on_disk
            dict["quantization_config"] = try quantization_config?.jsonValue
            return dict
        }
    }
    
}
/**
 * @description Type of internal tags, build from payload Distance function types used to compare vectors
 * @enum {string}
 */
public enum Distance: String, Codable {
    case cosine = "Cosine"
    case euclid = "Euclid"
    case dot = "Dot"
}

public struct HnswConfigDiff: Codable, JSONDecodableModel {
    /**
     * Format: uint
     * @description Number of edges per node in the index graph. Larger the value - more accurate the search, more space required.
     */
    public let m: UInt?
    /** 
     * Format: uint
     * @description Number of neighbours to consider during the index building. Larger the value - more accurate the search, more time required to build the index.
     */
    public let ef_construct: UInt?
    /**
     * Format: uint
     * @description Minimal size (in kilobytes) of vectors for additional payload-based indexing. If payload chunk is smaller than `full_scan_threshold_kb` additional indexing won't be used - in this case full-scan search should be preferred by query planner and additional indexing is not required. Note: 1Kb = 1 vector of size 256
     */
    public let full_scan_threshold: UInt?
    /**
     * Format: uint
     * @description Number of parallel threads used for background index building. If 0 - auto selection.
     */
    public let max_indexing_threads: UInt?
    /** @description Store HNSW index on disk. If set to false, the index will be stored in RAM. Default: false */
    public let on_disk: Bool?
    /**
     * Format: uint
     * @description Custom M param for additional payload-aware HNSW links. If not set, default M will be used.
     */
    public let payload_m: UInt?
    
    public init(m: UInt?,
                ef_construct: UInt?,
                full_scan_threshold: UInt?,
                max_indexing_threads: UInt?,
                on_disk: Bool?,
                payload_m: UInt?) {
        self.m = m
        self.ef_construct = ef_construct
        self.full_scan_threshold = full_scan_threshold
        self.max_indexing_threads = max_indexing_threads
        self.on_disk = on_disk
        self.payload_m = payload_m
    }
}

public enum QuantizationConfig: JSONEncodableModel, JSONDecodableModel {
    
    case scalar(ScalarQuantizationConfig)
    //    case product(ProductQuantizationConfig)
    
    public init(from json: JSON) throws {
        if json["scalar"].isExists {
            self = try .scalar(.decode(from: json["scalar"]))
        } else {
            throw QTError(.decode)
        }
    }
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .scalar(let config):
                return try config.jsonValue
            }
        }
    }
    
}

public struct ScalarQuantization: Codable {
    
    public let scalar: ScalarQuantizationConfig
    
}

public struct ScalarQuantizationConfig: Codable, JSONDecodableModel {
    public let type: ScalarType
    /**
     * Format: float
     * @description Quantile for quantization. Expected value range in [0.5, 1.0]. If not set - use the whole range of values
     */
    public let quantile: Float?
    /** @description If true - quantized vectors always will be stored in RAM, ignoring the config of main storage */
    public let always_ram: Bool?
}

/** @enum {string} */
public enum ScalarType: String, Codable {
    case int8
}
//struct ProductQuantization: JSONEncodableModel {
//    let product: ProductQuantizationConfig
//}
//struct ProductQuantizationConfig: JSONEncodableModel {
//    let compression: CompressionRatio
//    let always_ram: Bool?
//}
/** @enum {string} */
enum CompressionRatio: String, Codable {
    case x4, x8, x16, x32, x64
}
/** @description Config of HNSW index */
struct HnswConfig: JSONEncodableModel {
    /**
     * Format: uint
     * @description Number of edges per node in the index graph. Larger the value - more accurate the search, more space required.
     */
    let m: UInt
    /**
     * Format: uint
     * @description Number of neighbours to consider during the index building. Larger the value - more accurate the search, more time required to build the index.
     */
    let ef_construct: UInt
    /**
     * Format: uint
     * @description Minimal size (in kilobytes) of vectors for additional payload-based indexing. If payload chunk is smaller than `full_scan_threshold_kb` additional indexing won't be used - in this case full-scan search should be preferred by query planner and additional indexing is not required. Note: 1Kb = 1 vector of size 256
     */
    let full_scan_threshold: UInt
    /**
     * Format: uint
     * @description Number of parallel threads used for background index building. If 0 - auto selection.
     */
    let max_indexing_threads: UInt?
    /** @description Store HNSW index on disk. If set to false, the index will be stored in RAM. Default: false */
    let on_disk: Bool?
    /**
     * Format: uint
     * @description Custom M param for additional payload-aware HNSW links. If not set, default M will be used.
     */
    let payload_m: UInt?
    
    public init(from json: JSON) throws {
        self.m = json["m"].uIntValue
        self.ef_construct = json["ef_construct"].uIntValue
        self.full_scan_threshold = json["full_scan_threshold"].uIntValue
        self.max_indexing_threads = json["max_indexing_threads"].uInt
        self.on_disk = json["on_disk"].bool
        self.payload_m = json["payload_m"].uInt
    }
}


public struct OpimizersConfig: JSONEncodableModel {
    /**
     * Format: double
     * @description The minimal fraction of deleted vectors in a segment, required to perform segment optimization
     */
    let deleted_threshold: Double
    /**
     * Format: uint
     * @description The minimal number of vectors in a segment, required to perform segment optimization
     */
    let vacuum_min_vector_number: UInt
    /**
     * Format: uint
     * @description Target amount of segments optimizer will try to keep. Real amount of segments may vary depending on multiple parameters: - Amount of stored points - Current write RPS
     *
     * It is recommended to select default number of segments as a factor of the number of search threads, so that each segment would be handled evenly by one of the threads. If `default_segment_number = 0`, will be automatically selected by the number of available CPUs.
     */
    let default_segment_number: UInt
    /**
     * Format: uint
     * @description Do not create segments larger this size (in kilobytes). Large segments might require disproportionately long indexation times, therefore it makes sense to limit the size of segments.
     *
     * If indexing speed is more important - make this parameter lower. If search speed is more important - make this parameter higher. Note: 1Kb = 1 vector of size 256 If not set, will be automatically selected considering the number of available CPUs.
     * @default null
     */
    let max_segment_size: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors to store in-memory per segment. Segments larger than this threshold will be stored as read-only memmaped file.
     *
     * Memmap storage is disabled by default, to enable it, set this threshold to a reasonable value.
     *
     * To disable memmap storage, set this to `0`. Internally it will use the largest threshold possible.
     *
     * Note: 1Kb = 1 vector of size 256
     * @default null
     */
    let memmap_threshold: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors allowed for plain index, exceeding this threshold will enable vector indexing
     *
     * Default value is 20,000, based on <https://github.com/google-research/google-research/blob/master/scann/docs/algorithms.md>.
     *
     * To disable vector indexing, set to `0`.
     *
     * Note: 1kB = 1 vector of size 256.
     * @default null
     */
    let indexing_threshold: UInt?
    /**
     * Format: uint64
     * @description Minimum interval between forced flushes.
     */
    let flush_interval_sec: UInt64?
    /**
     * Format: uint
     * @description Maximum available threads for optimization workers
     */
    let max_optimization_threads: UInt
    
    public init(from json: JSON) throws {
        deleted_threshold = json["deleted_threshold"].doubleValue
        vacuum_min_vector_number = json["vacuum_min_vector_number"].uIntValue
        default_segment_number = json["default_segment_number"].uIntValue
        max_segment_size = json["max_segment_size"].uInt
        memmap_threshold = json["memmap_threshold"].uInt
        indexing_threshold = json["indexing_threshold"].uInt
        flush_interval_sec = json["flush_interval_sec"].uInt64
        max_optimization_threads = json["max_optimization_threads"].uIntValue
    }
}

struct WalConfig: JSONEncodableModel {
    /**
     * Format: uint
     * @description Size of a single WAL segment in MB
     */
    var wal_capacity_mb: UInt
    
    /**
     * Format: uint
     * @description Number of WAL segments to create ahead of actually used ones
     */
    var wal_segments_ahead: UInt
    
    init(from json: JSON) throws {
        wal_capacity_mb    = json["wal_capacity_mb"].uIntValue
        wal_segments_ahead = json["wal_segments_ahead"].uIntValue
    }
}

/** @description Display payload field type & index information */
struct PayloadIndexInfo: JSONEncodableModel {
    let data_type: PayloadSchemaType
    let params: PayloadSchemaParams?
    /**
     * Format: uint
     * @description Number of points indexed with this index
     */
    let points: UInt
    
    init(from json: JSON) throws {
        data_type = try PayloadSchemaType.decode(from: json["data_type"])
        points = json["points"].uIntValue
        params = try .init(from: json)
    }
    
}
/**
 * @description All possible names of payload types
 * @enum {string}
 */
public enum PayloadSchemaType: String, Codable {
    case keyword, integer, float, geo, text
}
///** @description Payload type with parameters */
public typealias PayloadSchemaParams = TextIndexParams

public struct TextIndexParams: JSONEncodableModel {
    public let type: TextIndexType
    public let tokenizer: TokenizerType?
    /** Format: uint */
    public let min_token_len: UInt?
    /** Format: uint */
    public let max_token_len: UInt?
    /** @description If true, lowercase all tokens. Default: true */
    public let lowercase: Bool?
    
    public init(from json: JSON) throws {
        type = try TextIndexType.decode(from: json["type"])
        tokenizer = try? TokenizerType.decodeIfPresent(from: json["tokenizer"])
        min_token_len = json["min_token_len"].uInt
        max_token_len = json["max_token_len"].uInt
        lowercase = json["lowercase"].bool
    }
}

/** @enum {string} */
public enum TextIndexType: String, Codable {
    case text
}

/** @enum {string} */
public enum TokenizerType: String, Codable {
    case prefix
    case whitespace
    case word
}

//struct PointRequest {
//    /** @description Look for points with ids */
//    let ids: [ExtendedPointId]
//    /** @description Select which payload to return with the response. Default: All */
//    let with_payload: WithPayloadInterface?
//    let with_vector: WithVector?
//}
///** @description Type, used for specifying point ID in user interface */
//
//enum ExtendedPointId {
//    case number(Int)
//    case uuid(String)
//}
//
/** @description Options for specifying which payload to include or not */
public enum WithPayloadInterface: JSONDecodableModel {
    case array([String])
    case payloadSelector(PayloadSelector)
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .array(let array):
                return array
            case .payloadSelector(let payload):
                return try payload.jsonValue
            }
        }
    }
}

/** @description Specifies how to treat payload selector */
public enum PayloadSelector: JSONDecodableModel {
    case include(PayloadSelectorInclude)
    case exclude(PayloadSelectorExclude)
   
    public var jsonValue: Any {
        get throws {
            switch self {
            case .include(let payload):
                return try payload.jsonValue
            case .exclude(let payload):
                return try payload.jsonValue
            }
        }
    }
}

public struct PayloadSelectorInclude: Codable, JSONDecodableModel {
    /** @description Only include this payload keys */
    public let include: [String]
    
    public init(include: [String]) {
        self.include = include
    }
}

public struct PayloadSelectorExclude: Codable, JSONDecodableModel {
    /** @description Exclude this fields from returning payload */
    public let exclude: [String]
    public init(exclude: [String]) {
        self.exclude = exclude
    }
}

///** @description Options for specifying which vector to include */
//enum WithVector {
//    case array([String])
//}
//
///** @description Point data */
//struct Record {
//    let id: ExtendedPointId
//    /** @description Payload - values assigned to the point */
//    let payload: Payload?
//    /** @description Vector of the point */
//    let vector: VectorStruct?
//}
//
//typealias Payload = [String: Any]
//
///** @description Full vector data per point separator with single and multiple vector modes */
public struct VectorStruct: JSONEncodableModel {
    
    public let vectors: [Decimal]
    
    public init(from json: JSON) throws {
        if let array = json.array {
            vectors = array.compactMap(\.decimal)
        } else {
            let json = json["additionalProperties"]
            vectors = json.arrayValue.compactMap(\.decimal)
        }
    }
    
}

///** @description Search request. Holds all conditions and parameters for the search of most similar points by vector similarity given the filtering restrictions. */
public struct SearchRequest: JSONDecodableModel {
    public let vector: NamedVectorStruct
    /** @description Look only for points which satisfies this conditions */
    public let filter: Filter?
    /** @description Additional search params */
    public let params: SearchParams?
    /**
     * Format: uint
     * @description Max number of result to return
     */
    public let limit: UInt
    /**
     * Format: uint
     * @description Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.
     * @default 0
     */
    public let offset: UInt?
    /** @description Select which payload to return with the response. Default: None */
    public let with_payload: Bool?
    /**
     * @description Whether to return the point vector with the result?
     * @default null
     */
    public let with_vector: Bool?
    /**
     * Format: float
     * @description Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
     */
    public let score_threshold: Float?
    
    public init(vector: NamedVectorStruct,
                filter: Filter? = nil,
                params: SearchParams? = nil,
                limit: UInt,
                offset: UInt? = nil,
                with_payload: Bool? = nil,
                with_vector: Bool? = nil,
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
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["vector"] = try vector.jsonValue
            dict["filter"] = try filter?.jsonValue
            dict["params"] = try params?.jsonValue
            dict["limit"] = limit
            dict["offset"] = offset
            dict["with_payload"] = with_payload
            dict["with_vector"] = with_vector
            dict["score_threshold"] = score_threshold
            return dict
        }
    }
}
/**
 * @description Vector data separator for named and unnamed modes Unanmed mode:
 *
 * { "vector": [1.0, 2.0, 3.0] }
 *
 * or named mode:
 *
 * { "vector": { "vector": [1.0, 2.0, 3.0], "name": "image-embeddings" } }
 */
public enum NamedVectorStruct: JSONDecodableModel {
    case vector([Decimal])
    case namedVector(NamedVector)
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .vector(let array):
                return array
            case .namedVector(let object):
                return try object.jsonValue
            }
        }
    }
}

/** @description Vector data with name */
public struct NamedVector: Codable, JSONDecodableModel {
    /** @description Name of vector data */
    public let name: String
    /** @description Vector data */
    public let vector: [Decimal]
    
    public init(name: String, vector: [Decimal]) {
        self.name = name
        self.vector = vector
    }
}
public struct Filter: JSONDecodableModel {
    /** @description At least one of those conditions should match */
    public let should: [Condition]
    /** @description All conditions must match */
    public let must: [Condition]
    /** @description All conditions must NOT match */
    public let must_not: [Condition]
    
    public init(should: [Condition] = [],
                must: [Condition] = [],
                must_not: [Condition] = []) {
        self.should = should
        self.must = must
        self.must_not = must_not
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["should"]   = should.isEmpty   ? nil : try should.jsonValue
            dict["must"]     = must.isEmpty     ? nil : try must.jsonValue
            dict["must_not"] = must_not.isEmpty ? nil : try must_not.jsonValue
            return dict
        }
    }
}

public enum Condition: JSONDecodableModel {
    case field(FieldCondition)
    case isEmpty(IsEmptyCondition)
    case isNull(IsNullCondition)
    case hasId(HasIdCondition)
    case nested(NestedCondition)
    case filter(Filter)
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .field(let condition):
                return try condition.jsonValue
            case .isEmpty(let condition):
                return try condition.jsonValue
            case .isNull(let condition):
                return try condition.jsonValue
            case .hasId(let condition):
                return try condition.jsonValue
            case .nested(let condition):
                return try condition.jsonValue
            case .filter(let condition):
                return try condition.jsonValue
            }
        }
    }
}
/** @description All possible payload filtering conditions */
public struct FieldCondition: JSONDecodableModel {
    /** @description Payload key */
    public let key: String
    /** @description Check if point has field with a given value */
    public let match: Match?
    /** @description Check if points value lies in a given range */
    public let range: Range?
    /** @description Check if points geo location lies in a given area */
    public let geo_bounding_box: QTGeoBoundingBox?
    /** @description Check if geo point is within a given radius */
    public let geo_radius: GeoRadius?
    /** @description Check number of values of the field */
    public let values_count: QTValuesCount?
    
    public init(key: String,
                match: Match? = nil,
                range: Range? = nil,
                geo_bounding_box: QTGeoBoundingBox? = nil,
                geo_radius: GeoRadius? = nil,
                values_count: QTValuesCount? = nil) {
        self.key = key
        self.match = match
        self.range = range
        self.geo_bounding_box = geo_bounding_box
        self.geo_radius = geo_radius
        self.values_count = values_count
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["key"] = key
            dict["match"] = try match?.jsonValue
            dict["range"] = try range?.jsonValue
            dict["geo_bounding_box"] = try geo_bounding_box?.jsonValue
            dict["geo_radius"]   = try geo_radius?.jsonValue
            dict["values_count"] = try values_count?.jsonValue
            return dict
        }
    }
}

public enum ExtendedPointId: JSONDecodableModel, JSONEncodableModel {
    
    case string(String)
    case integer(Int)
    
    public init(from json: JSON) throws {
        if let value = json.string {
            self = .string(value)
        } else if let value = json.int {
            self = .integer(value)
        } else {
            throw QTError.encode
        }
    }
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .string(let string):
                return string
            case .integer(let int):
                return int
            }
        }
    }
    
}

/** @description Match filter request */
public enum Match: JSONDecodableModel {
    case value(MatchValue)
    case text(MatchText)
    case any(MatchAny)
    case except(MatchExcept)
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .value(let value):
                return try value.jsonValue
            case .text(let value):
                return try value.jsonValue
            case .any(let value):
                return try value.jsonValue
            case .except(let value):
                return try value.jsonValue
            }
        }
    }
}

/** @description Exact match of the given value */
public struct MatchValue: JSONDecodableModel {
    public let value: ValueVariants
    
    public init(value: ValueVariants) {
        self.value = value
    }
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["value"] = try value.jsonValue
            return dict
        }
    }
}

public enum ValueVariants: JSONDecodableModel {
    case string(String)
    case number(Decimal)
    case bool(Bool)
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .string(let string):
                return string
            case .number(let value):
                return value
            case .bool(let value):
                return value
            }
        }
    }
    
}

/** @description Full-text match of the strings. */
public struct MatchText: Codable, JSONDecodableModel {
    public let text: String
    public init(text: String) {
        self.text = text
    }
}
/** @description Exact match on any of the given values */
public struct MatchAny: JSONDecodableModel {
    let any: AnyVariants
    
    public init(any: AnyVariants) {
        self.any = any
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["any"] = try any.jsonValue
            return dict
        }
    }
}

public enum AnyVariants: JSONDecodableModel {
    
    case strings([String])
    case numbers([Decimal])
    
    public var jsonValue: Any {
        get throws {
            switch self {
            case .strings(let value):
                return value
            case .numbers(let value):
                return value
            }
        }
    }
    
}

/** @description Should have at least one value not matching the any given values */
public struct MatchExcept: JSONDecodableModel {
    public let except: AnyVariants
    public init(except: AnyVariants) {
        self.except = except
    }
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["except"] = try except.jsonValue
            return dict
        }
    }
}
/** @description Range filter request */
public struct Range: Codable, JSONDecodableModel {
    /**
     * Format: double
     * @description point.key < range.lt
     */
    public var lt: Double?
    
    /**
     * Format: double
     * @description point.key > range.gt
     */
    public var gt: Double?
    
    /**
     * Format: double
     * @description point.key >= range.gte
     */
    public var gte: Double?
    
    /**
     * Format: double
     * @description point.key <= range.lte
     */
    public var lte: Double?
    
    init(lt: Double? = nil, gt: Double? = nil, gte: Double? = nil, lte: Double? = nil) {
        self.lt = lt
        self.gt = gt
        self.gte = gte
        self.lte = lte
    }
}

/**
 * @description Geo filter request
 *
 * Matches coordinates inside the rectangle, described by coordinates of lop-left and bottom-right edges
 */
public struct QTGeoBoundingBox: Codable, JSONDecodableModel {
    public let top_left: GeoPoint
    public let bottom_right: GeoPoint
    
    public init(top_left: GeoPoint, bottom_right: GeoPoint) {
        self.top_left = top_left
        self.bottom_right = bottom_right
    }
}
/** @description Geo point payload schema */
public struct GeoPoint: Codable, JSONDecodableModel {
    public var lon: Double
    public var lat: Double
    public init(lon: Double, lat: Double) {
        self.lon = lon
        self.lat = lat
    }
}
/**
 * @description Geo filter request
 *
 * Matches coordinates inside the circle of `radius` and center with coordinates `center`
 */
public struct GeoRadius: Codable, JSONDecodableModel {
    public let center: GeoPoint
    /**
     * Format: double
     * @description Radius of the area in meters
     */
    public let radius: Double
    public init(center: GeoPoint, radius: Double) {
        self.center = center
        self.radius = radius
    }
}

/** @description Values count filter request */
public struct QTValuesCount: Codable, JSONDecodableModel {
    /**
     * Format: uint
     * @description point.key.length() < values_count.lt
     */
    public var lt: UInt?
    
    /**
     * Format: uint
     * @description point.key.length() > values_count.gt
     */
    public var gt: UInt?
    
    /**
     * Format: uint
     * @description point.key.length() >= values_count.gte
     */
    public var gte: UInt?
    
    /**
     * Format: uint
     * @description point.key.length() <= values_count.lte
     */
    public var lte: UInt?
    
    public init(lt: UInt? = nil, gt: UInt? = nil, gte: UInt? = nil, lte: UInt? = nil) {
        self.lt = lt
        self.gt = gt
        self.gte = gte
        self.lte = lte
    }
}
/** @description Select points with empty payload for a specified field */
public struct IsEmptyCondition: Codable, JSONDecodableModel {
    public var is_empty: PayloadField
    public init(is_empty: PayloadField) {
        self.is_empty = is_empty
    }
}
/** @description Payload field */
public struct PayloadField: Codable, JSONDecodableModel {
    /** @description Payload field name */
    public var key: String
    public init(key: String) {
        self.key = key
    }
}
/** @description Select points with null payload for a specified field */
public struct IsNullCondition: Codable, JSONDecodableModel {
    public var is_null: PayloadField
    public init(is_null: PayloadField) {
        self.is_null = is_null
    }
}
/** @description ID-based filtering condition */
public struct HasIdCondition: JSONDecodableModel {
    public let has_id: [ExtendedPointId]
    public init(has_id: [ExtendedPointId]) {
        self.has_id = has_id
    }
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["has_id"] = try has_id.jsonValue
            return dict
        }
    }
}

public struct NestedCondition: JSONDecodableModel {
    public let nested: Nested
    public init(nested: Nested) {
        self.nested = nested
    }
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["nested"] = try nested.jsonValue
            return dict
        }
    }
}

/** @description Select points with payload for a specified nested field */
public struct Nested: JSONDecodableModel {
    public let key: String
    public let filter: Filter
    public init(key: String, filter: Filter) {
        self.key = key
        self.filter = filter
    }
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["key"] = key
            dict["filter"] = try filter.jsonValue
            return dict
        }
    }
}
/** @description Additional parameters of the search */
public struct SearchParams: Codable, JSONDecodableModel {
    /**
     * Format: uint
     * @description Params relevant to HNSW index /// Size of the beam in a beam-search. Larger the value - more accurate the result, more time required for search.
     */
    public let hnsw_ef: Int?
    /**
     * @description Search without approximation. If set to true, search may run long but with exact results.
     * @default false
     */
    public let exact: Bool?
    /**
     * @description Quantization params
     * @default null
     */
    public let quantization: QuantizationSearchParams?
    public init(hnsw_ef: Int?, exact: Bool?, quantization: QuantizationSearchParams?) {
        self.hnsw_ef = hnsw_ef
        self.exact = exact
        self.quantization = quantization
    }
}
/** @description Additional parameters of the search */
public struct QuantizationSearchParams: Codable {
    /**
     * @description If true, quantized vectors are ignored. Default is false.
     * @default false
     */
    public let ignore: Bool?
    /**
     * @description If true, use original vectors to re-score top-k results. Might require more time in case if original vectors are stored on disk. Default is false.
     * @default false
     */
    public let rescore: Bool?
    
    public init(ignore: Bool?, rescore: Bool?) {
        self.ignore = ignore
        self.rescore = rescore
    }
}
/** @description Search result */
public struct ScoredPoint: JSONEncodableModel {
    public let id: ExtendedPointId
    /**
     * Format: uint64
     * @description Point version
     */
    public let version: UInt64
    /**
     * Format: float
     * @description Points vector distance to the query vector
     */
    public let score: Decimal
    /** @description Payload - values assigned to the point */
    public let payload: [String: Any]
    /** @description Vector of the point */
    public let vector: VectorStruct?
    
    public init(from json: JSON) throws {
        id = try .init(from: json["id"])
        version = json["version"].uInt64Value
        score = json["score"].decimalValue
        payload = json["payload"].dictionaryObjectValue
        vector = try .init(from: json["vector"])
    }
}
public struct UpdateResult: Codable {
    /**
     * Format: uint64
     * @description Sequential number of the operation
     */
    public let operation_id: UInt64
    public let status: UpdateStatus
}
///**
// * @description
// *  - `Acknowledged`: Request is saved to WAL and will be process in a queue.
// *  - `Completed`: Request is completed, changes are actual.
// * @enum {string}
// */
public enum UpdateStatus: String, Codable {
    /// Request is saved to WAL and will be process in a queue.
    case acknowledged
    /// Request is completed, changes are actual.
    case completed
}
///**
// * @description Recommendation request. Provides positive and negative examples of the vectors, which are already stored in the collection.
// *
// * Service should look for the points which are closer to positive examples and at the same time further to negative examples. The concrete way of how to compare negative and positive distances is up to implementation in `segment` crate.
// */
//struct RecommendRequest {
//    /** @description Look for vectors closest to those */
//    let positive: [ExtendedPointId]
//    /**
//     * @description Try to avoid vectors like this
//     * @default []
//     */
//    let negative: [ExtendedPointId]?
//    /** @description Look only for points which satisfies this conditions */
//    let filter: Filter?
//    /** @description Additional search params */
//    let params: SearchParams?
//    /**
//     * Format: uint
//     * @description Max number of result to return
//     */
//    let limit: UInt
//    /**
//     * Format: uint
//     * @description Offset of the first result to return. May be used to paginate results. Note: large offset values may cause performance issues.
//     * @default 0
//     */
//    let offset: UInt?
//    /** @description Select which payload to return with the response. Default: None */
//   let with_payload: WithPayloadInterface?
//    /**
//     * @description Whether to return the point vector with the result?
//     * @default null
//     */
//   let with_vector?: WithVector?
//    /**
//     * Format: float
//     * @description Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
//     */
//    let score_threshold: Float?
//    /**
//     * @description Define which vector to use for recommendation, if not specified - try to use default vector
//     * @default null
//     */
//    let using: UsingVector?
//    /**
//     * @description The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
//     * @default null
//     */
//   let lookup_from: LookupLocation?
//}
//
//typealias UsingVector = String
///** @description Defines a location to use for looking up the vector. Specifies collection and vector field name. */
//struct LookupLocation {
//    /** @description Name of the collection used for lookup */
//    let collection: String
//    /**
//     * @description Optional name of the vector field within the collection. If not provided, the default vector field will be used.
//     * @default null
//     */
//    let vector: String?
//}
///** @description Scroll request - paginate over all points which matches given condition */
//struct ScrollRequest {
//    /** @description Start ID to read points from. */
//    let offset: ExtendedPointId?
//    /**
//     * Format: uint
//     * @description Page size. Default: 10
//     */
//    let limit: UInt?
//    /** @description Look only for points which satisfies this conditions. If not provided - all points. */
//    let filter: Filter?
//    /** @description Select which payload to return with the response. Default: All */
//    let with_payload: WithPayloadInterface?
//    let with_vector: WithVector?
//};
///** @description Result of the points read request */
//struct ScrollResult {
//    /** @description List of retrieved points */
//    let points: [Record]
//    /** @description Offset which should be used to retrieve a next page result */
//    let next_page_offset: ExtendedPointId?
//}
///** @description Operation for creating new collection and (optionally) specify index params */
public struct CreateCollection: JSONDecodableModel {
    public let vectors: VectorParams
    /**
     * Format: uint32
     * @description Number of shards in collection. Default is 1 for standalone, otherwise equal to the number of nodes Minimum is 1
     * @default null
     */
    public let shard_number: UInt32?
    /**
     * Format: uint32
     * @description Number of shards replicas. Default is 1 Minimum is 1
     * @default null
     */
    public let replication_factor: UInt32?
    /**
     * Format: uint32
     * @description Defines how many replicas should apply the operation for us to consider it successful. Increasing this number will make the collection more resilient to inconsistencies, but will also make it fail if not enough replicas are available. Does not have any performance impact.
     * @default null
     */
    public let write_consistency_factor: UInt32?
    /**
     * @description If true - point's payload will not be stored in memory. It will be read from the disk every time it is requested. This setting saves RAM by (slightly) increasing the response time. Note: those payload values that are involved in filtering and are indexed - remain in RAM.
     * @default null
     */
    public let on_disk_payload: Bool?
    /** @description Custom params for HNSW index. If none - values from service configuration file are used. */
    public let hnsw_config: HnswConfigDiff?
    /** @description Custom params for WAL. If none - values from service configuration file are used. */
    public let wal_config: WalConfigDiff?
    /** @description Custom params for Optimizers.  If none - values from service configuration file are used. */
    public let optimizers_config: OptimizersConfigDiff?
    /**
     * @description Specify other collection to copy data from.
     * @default null
     */
    public let init_from: InitFrom?
    /**
     * @description Quantization parameters. If none - quantization is disabled.
     * @default null
     */
    public let quantization_config: QuantizationConfig?
    
    public init(vectors: VectorParams,
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
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["vectors"] = try vectors.jsonValue
            dict["shard_number"] = shard_number
            dict["replication_factor"] = replication_factor
            dict["write_consistency_factor"] = write_consistency_factor
            dict["on_disk_payload"] = on_disk_payload
            dict["hnsw_config"] = try hnsw_config?.jsonValue
            dict["wal_config"] = try wal_config?.jsonValue
            dict["optimizers_config"] = try optimizers_config?.jsonValue
            dict["init_from"] = try init_from?.jsonValue
            return dict
        }
    }
}
public struct WalConfigDiff: Codable, JSONDecodableModel {
    /**
     * Format: uint
     * @description Size of a single WAL segment in MB
     */
    public let wal_capacity_mb: UInt?
    /**
     * Format: uint
     * @description Number of WAL segments to create ahead of actually used ones
     */
    public let wal_segments_ahead: UInt?
    
    public init(wal_capacity_mb: UInt?, wal_segments_ahead: UInt?) {
        self.wal_capacity_mb = wal_capacity_mb
        self.wal_segments_ahead = wal_segments_ahead
    }
}

public struct OptimizersConfig: JSONEncodableModel {
    /**
     * Format: double
     * @description The minimal fraction of deleted vectors in a segment, required to perform segment optimization
     */
    let deleted_threshold: Double
    /**
     * Format: uint
     * @description The minimal number of vectors in a segment, required to perform segment optimization
     */
    let vacuum_min_vector_number: UInt
    /**
     * Format: uint
     * @description Target amount of segments optimizer will try to keep. Real amount of segments may vary depending on multiple parameters: - Amount of stored points - Current write RPS
     *
     * It is recommended to select default number of segments as a factor of the number of search threads, so that each segment would be handled evenly by one of the threads If `default_segment_number = 0`, will be automatically selected by the number of available CPUs
     */
    let default_segment_number: UInt
    /**
     * Format: uint
     * @description Do not create segments larger this size (in kilobytes). Large segments might require disproportionately long indexation times, therefore it makes sense to limit the size of segments.
     *
     * If indexation speed have more priority for your - make this parameter lower. If search speed is more important - make this parameter higher. Note: 1Kb = 1 vector of size 256
     */
    let max_segment_size: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors to store in-memory per segment. Segments larger than this threshold will be stored as read-only memmaped file.
     *
     * Memmap storage is disabled by default, to enable it, set this threshold to a reasonable value.
     *
     * To disable memmap storage, set this to `0`.
     *
     * Note: 1Kb = 1 vector of size 256
     */
    let memmap_threshold: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors allowed for plain index, exceeding this threshold will enable vector indexing
     *
     * Default value is 20,000, based on <https://github.com/google-research/google-research/blob/master/scann/docs/algorithms.md>.
     *
     * To disable vector indexing, set to `0`.
     *
     * Note: 1kB = 1 vector of size 256.
     */
    let indexing_threshold: UInt?
    /**
     * Format: uint64
     * @description Minimum interval between forced flushes.
     */
    let flush_interval_sec: UInt64
    /**
     * Format: uint
     * @description Maximum available threads for optimization workers
     */
    let max_optimization_threads: UInt
    
    public init(from json: JSON) throws {
        deleted_threshold = json["deleted_threshold"].doubleValue
        vacuum_min_vector_number = json["vacuum_min_vector_number"].uIntValue
        default_segment_number = json["default_segment_number"].uIntValue
        max_segment_size = json["max_segment_size"].uInt
        memmap_threshold = json["memmap_threshold"].uInt
        indexing_threshold = json["indexing_threshold"].uInt
        flush_interval_sec = json["flush_interval_sec"].uInt64Value
        max_optimization_threads = json["max_optimization_threads"].uIntValue
    }
}

public struct OptimizersConfigDiff: Codable, JSONDecodableModel {
    /**
     * Format: double
     * @description The minimal fraction of deleted vectors in a segment, required to perform segment optimization
     */
    public let deleted_threshold: Double?
    /**
     * Format: uint
     * @description The minimal number of vectors in a segment, required to perform segment optimization
     */
    public let vacuum_min_vector_number: UInt?
    /**
     * Format: uint
     * @description Target amount of segments optimizer will try to keep. Real amount of segments may vary depending on multiple parameters: - Amount of stored points - Current write RPS
     *
     * It is recommended to select default number of segments as a factor of the number of search threads, so that each segment would be handled evenly by one of the threads If `default_segment_number = 0`, will be automatically selected by the number of available CPUs
     */
    public let default_segment_number: UInt?
    /**
     * Format: uint
     * @description Do not create segments larger this size (in kilobytes). Large segments might require disproportionately long indexation times, therefore it makes sense to limit the size of segments.
     *
     * If indexation speed have more priority for your - make this parameter lower. If search speed is more important - make this parameter higher. Note: 1Kb = 1 vector of size 256
     */
    public let max_segment_size: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors to store in-memory per segment. Segments larger than this threshold will be stored as read-only memmaped file.
     *
     * Memmap storage is disabled by default, to enable it, set this threshold to a reasonable value.
     *
     * To disable memmap storage, set this to `0`.
     *
     * Note: 1Kb = 1 vector of size 256
     */
    public let memmap_threshold: UInt?
    /**
     * Format: uint
     * @description Maximum size (in kilobytes) of vectors allowed for plain index, exceeding this threshold will enable vector indexing
     *
     * Default value is 20,000, based on <https://github.com/google-research/google-research/blob/master/scann/docs/algorithms.md>.
     *
     * To disable vector indexing, set to `0`.
     *
     * Note: 1kB = 1 vector of size 256.
     */
    public let indexing_threshold: UInt?
    /**
     * Format: uint64
     * @description Minimum interval between forced flushes.
     */
    public let flush_interval_sec: UInt64?
    /**
     * Format: uint
     * @description Maximum available threads for optimization workers
     */
    public let max_optimization_threads: UInt?
    
    public init(deleted_threshold: Double?,
                vacuum_min_vector_number: UInt?,
                default_segment_number: UInt?,
                max_segment_size: UInt?,
                memmap_threshold: UInt?,
                indexing_threshold: UInt?,
                flush_interval_sec: UInt64?,
                max_optimization_threads: UInt?) {
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

///** @description Operation for creating new collection and (optionally) specify index params */
public struct InitFrom: Codable, JSONDecodableModel {
    
    public let collection: String
    
    public init(collection: String) {
        self.collection = collection
    }
    
}
///** @description Operation for updating parameters of the existing collection */
//struct UpdateCollection {
//    /** @description Custom params for Optimizers.  If none - values from service configuration file are used. This operation is blocking, it will only proceed ones all current optimizations are complete */
//    let optimizers_config: OptimizersConfigDiff?
//    /** @description Collection base params.  If none - values from service configuration file are used. */
//    let params: CollectionParamsDiff?
//}
//struct CollectionParamsDiff {
//    /**
//     * Format: uint32
//     * @description Number of replicas for each shard
//     */
//    let replication_factor: UInt32?
//    /**
//     * Format: uint32
//     * @description Minimal number successful responses from replicas to consider operation successful
//     */
//    let write_consistency_factor: UInt32?
//}
///** @description Operation for performing changes of collection aliases. Alias changes are atomic, meaning that no collection modifications can happen between alias operations. */
//struct ChangeAliasesOperation {
//    let actions: [AliasOperations]
//}
///** @description Group of all the possible operations related to collection aliases */
//AliasOperations: components["schemas"]["CreateAliasOperation"] | components["schemas"]["DeleteAliasOperation"] | components["schemas"]["RenameAliasOperation"];
//struct CreateAliasOperation {
//    let create_alias: CreateAlias
//}
///** @description Create alternative name for a collection. Collection will be available under both names for search, retrieve, */
//struct CreateAlias {
//    let collection_name: String
//    let alias_name: String
//}
///** @description Delete alias if exists */
//struct DeleteAliasOperation {
//    let delete_alias: DeleteAlias
//}
///** @description Delete alias if exists */
//struct DeleteAlias {
//    let alias_name: String
//}
///** @description Change alias to a new one */
//struct RenameAliasOperation {
//    let rename_alias: RenameAlias
//}
///** @description Change alias to a new one */
//struct RenameAlias {
//    let old_alias_name: String
//    let new_alias_name: String
//}
//struct CreateFieldIndex {
//    let field_name: String
//    let field_schema: PayloadFieldSchema?
//};
//PayloadFieldSchema: components["schemas"]["PayloadSchemaType"] | components["schemas"]["PayloadSchemaParams"];
//PointsSelector: components["schemas"]["PointIdsList"] | components["schemas"]["FilterSelector"];
//struct PointIdsList {
//    let points: [ExtendedPointId]
//};
//struct FilterSelector {
//    let filter: Filter
//};
//PointInsertOperations: components["schemas"]["PointsBatch"] | components["schemas"]["PointsList"];
//BatchVectorStruct: ((number)[])[] | ({
//    [key: string]: ((number)[])[] | undefined;
//});
public struct QTPointStruct: JSONDecodableModel {
    
    public let id: Int
    public let vector: [Decimal]
    /** @description Payload values (optional) */
    public let payload: [String: Any]
    
    public init(id: Int, vector: [Decimal], payload: [String : Any] = [:]) {
        self.id = id
        self.vector = vector
        self.payload = payload
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["id"] = id
            dict["vector"] = vector
            dict["payload"] = payload.isEmpty ? nil : payload
            return dict
        }
    }
    
}
//struct Batch {
//    let ids: [ExtendedPointId]
//    let vectors: BatchVectorStruct
//    let payloads: Payload?
//}
//struct PointsBatch {
//    let batch: Batch
//}
public struct QTPointsList: JSONDecodableModel {
    
    public let points: [QTPointStruct]
    
    public init(points: [QTPointStruct]) {
        self.points = points
    }
    
    public var jsonValue: Any {
        get throws {
            var dict = [String: Any]()
            dict["points"] = try points.jsonValue
            return dict
        }
    }
}
//struct SetPayload {
//    let payload: Payload
//    /** @description Assigns payload to each point in this list */
//    let points: [ExtendedPointId]?
//    /** @description Assigns payload to each point that satisfy this filter condition */
//    let filter: Filter?
//}
//struct DeletePayload {
//    /** @description List of payload keys to remove from payload */
//    let keys: [String]
//    /** @description Deletes values from each point in this list */
//    let points: [ExtendedPointId]?
//    /** @description Deletes values from points that satisfy this filter condition */
//    let filter: Filter?
//}
///** @description Information about current cluster status and structure */
//ClusterStatus: OneOf<[{
//    /** @enum {string} */
//status: "disabled";
//}, {
//    /** @enum {string} */
//status: "enabled";
//    /**
//     * Format: uint64
//     * @description ID of this peer
//     */
//peer_id: number;
//    /** @description Peers composition of the cluster with main information */
//peers: {
//    [key: string]: components["schemas"]["PeerInfo"] | undefined;
//};
//raft_info: components["schemas"]["RaftInfo"];
//consensus_thread_status: components["schemas"]["ConsensusThreadStatus"];
//    /** @description Consequent failures of message send operations in consensus by peer address. On the first success to send to that peer - entry is removed from this hashmap. */
//message_send_failures: {
//    [key: string]: components["schemas"]["MessageSendErrors"] | undefined;
//};
//}]>;
///** @description Information of a peer in the cluster */
//struct PeerInfo {
//    let uri: String
//}
///** @description Summary information about the current raft state */
//struct RaftInfo {
//    /**
//     * Format: uint64
//     * @description Raft divides time into terms of arbitrary length, each beginning with an election. If a candidate wins the election, it remains the leader for the rest of the term. The term number increases monotonically. Each server stores the current term number which is also exchanged in every communication.
//     */
//    let term: UInt64
//    /**
//     * Format: uint64
//     * @description The index of the latest committed (finalized) operation that this peer is aware of.
//     */
//    let commit: UInt64
//    /**
//     * Format: uint
//     * @description Number of consensus operations pending to be applied on this peer
//     */
//    let pending_operations: UInt
//    /**
//     * Format: uint64
//     * @description Leader of the current term
//     */
//    let leader: UInt64?
//    /** @description Role of this peer in the current term */
//    let role: StateRole?
//    /** @description Is this peer a voter or a learner */
//    let is_voter: Bool
//}
///**
// * @description Role of the peer in the consensus
// * @enum {string}
// */
//enum StateRole: String {
//    case follower = "Follower"
//    case candidate = "Candidate"
//    case leader = "Leader"
//    case preCandidate = "PreCandidate"
//}
///** @description Information about current consensus thread status */
//enum ConsensusThreadStatus {
//
//    case working(last_update: String)
//    case stopped
//    case stopped_with_err(String)
//
//    init?(from json: JSONObject) {
//        guard let kind = json["consensus_thread_status"]?.string else { return nil }
//        switch kind {
//        case "working":
//            guard let last_update = json["last_update"]?.string else { return nil }
//            self = .working(last_update: last_update)
//        case "stopped":
//            self = .stopped
//        case "stopped_with_err":
//            guard let err = json["err"]?.string else { return nil }
//            self = .stopped_with_err(err)
//        default:
//            return nil
//        }
//    }
//
//}
//
///** @description Message send failures for a particular peer */
//struct MessageSendErrors {
//    /** Format: uint */
//    let count: UInt
//    let latest_error: String?
//}
//struct SnapshotDescription {
//    let name: String
//    /** Format: partial-date-time */
//    let creation_time: String?
//    /** Format: uint64 */
//    let size: UInt64
//}
///** @description Count Request Counts the number of points which satisfy the given filter. If filter is not provided, the count of all points in the collection will be returned. */
//struct CountRequest {
//    /** @description Look only for points which satisfies this conditions */
//    let filter: Filter?
//    /**
//     * @description If true, count exact number of points. If false, count approximate number of points faster. Approximate count might be unreliable during the indexing process. Default: true
//     * @default true
//     */
//    let exact: Bool?
//}
//struct CountResult {
//    /**
//     * Format: uint
//     * @description Number of points which satisfy the conditions
//     */
//    let count: UInt
//}
///** @description Current clustering distribution for the collection */
//struct CollectionClusterInfo {
//    /**
//     * Format: uint64
//     * @description ID of this peer
//     */
//    let peer_id: UInt64
//    /**
//     * Format: uint
//     * @description Total number of shards
//     */
//    let shard_count: UInt
//    /** @description Local shards */
//    let local_shards: [LocalShardInfo]
//    /** @description Remote shards */
//    let remote_shards: [RemoteShardInfo]
//    /** @description Shard transfers */
//    let shard_transfers: [ShardTransferInfo]
//}
//struct LocalShardInfo {
//    /**
//     * Format: uint32
//     * @description Local shard id
//     */
//    let shard_id: UInt32
//    /**
//     * Format: uint
//     * @description Number of points in the shard
//     */
//    let points_count: UInt
//    let state: ReplicaState
//};
///**
// * @description State of the single shard within a replica set.
// * @enum {string}
// */
//enum ReplicaState: String {
//    case active = "Active"
//    case dead = "Dead"
//    case partial = "Partial"
//    case initializing = "Initializing"
//    case listener = "Listener"
//}
//struct RemoteShardInfo {
//    /**
//     * Format: uint32
//     * @description Remote shard id
//     */
//    let shard_id: UInt32
//    /**
//     * Format: uint64
//     * @description Remote peer id
//     */
//    let peer_id: UInt64
//    let state: ReplicaState
//}
//struct ShardTransferInfo {
//    /** Format: uint32 */
//    let shard_id: UInt32
//    /** Format: uint64 */
//    let from: UInt64
//    /** Format: uint64 */
//    let to: UInt64
//    /** @description If `true` transfer is a synchronization of a replicas If `false` transfer is a moving of a shard from one peer to another */
//    let sync: Bool
//}
//struct TelemetryData {
//    let id: String
//    let app: AppBuildTelemetry
//    let collections: CollectionsTelemetry
//    let cluster: ClusterTelemetry
//    let requests: RequestsTelemetry
//}
//struct AppBuildTelemetry {
//    let name: String
//    let version: String
//    let features: AppFeaturesTelemetry?
//    let system: RunningEnvironmentTelemetry?
//    /** Format: date-time */
//    let startup: String
//}
//struct AppFeaturesTelemetry {
//    let debug: Bool
//    let web_feature: Bool
//    let service_debug_feature: Bool
//}
//struct RunningEnvironmentTelemetry {
//    let distribution: String?
//    let distribution_version: String?
//    let is_docker: Bool
//    /** Format: uint */
//    let cores: UInt?
//    /** Format: uint */
//    let ram_size: UInt?
//    /** Format: uint */
//    let disk_size: UInt?
//    let cpu_flags: String
//};
//struct CollectionsTelemetry {
//    /** Format: uint */
//    let number_of_collections: UInt;
//    let collections: [CollectionTelemetryEnum]?
//};
//
//enum CollectionTelemetryEnum {
//    case telemetry(CollectionTelemetry)
//    case aggregatedTelemetry(CollectionsAggregatedTelemetry)
//
//    init(from json: JSONObject) throws {
//        if let telemetry = components["schemas"]?["CollectionTelemetry"] as? Telemetry {
//            self = .telemetry(telemetry)
//        } else if let aggregatedTelemetry = components["schemas"]?["CollectionsAggregatedTelemetry"] as? CollectionsAggregatedTelemetry {
//            self = .aggregatedTelemetry(aggregatedTelemetry)
//        } else {
//            throw QTError.decode
//        }
//    }
//}
//
//CollectionTelemetryEnum: components["schemas"]["CollectionTelemetry"] | components["schemas"]["CollectionsAggregatedTelemetry"];
//
//struct CollectionTelemetry {
//    let id: String
//    /** Format: uint64 */
//    let init_time_ms: UInt64
//    let config: CollectionConfig
//    let shards: [ReplicaSetTelemetry]
//    let transfers: [ShardTransferInfo]
//
//    init(from json: JSONObject) throws {
//        guard let id = json["id"]?.string else { throw QTError.decode }
//        self.id = id
//        self.init_time_ms = json["init_time_ms"]?.uint64Value ?? 0
//        self
//    }
//
//}
//struct ReplicaSetTelemetry {
//    /** Format: uint32 */
//    let id: UInt32
//    let local: LocalShardTelemetry?
//    let remote: [RemoteShardTelemetry]
//    var replicateStates: [String: ReplicaState]
//}
//struct LocalShardTelemetry {
//    let variant_name: String?
//    let segments: [SegmentTelemetry]
//    let optimizations: OptimizerTelemetry
//}
//struct SegmentTelemetry {
//    let info: SegmentInfo
//    let config: SegmentConfig
//    let vector_index_searches: [VectorIndexSearchesTelemetry]
//    let payload_field_indices: [PayloadIndexTelemetry]
//}
///** @description Aggregated information about segment */
//struct SegmentInfo {
//    let segment_type: SegmentType
//    /** Format: uint */
//    let num_vectors: UInt
//    /** Format: uint */
//    let num_points: UInt
//    /** Format: uint */
//    let num_deleted_vectors: UInt
//    /** Format: uint */
//    let ram_usage_bytes: UInt
//    /** Format: uint */
//    let disk_usage_bytes: UInt
//    let is_appendable: Bool
//    let index_schema: {
//        [key: string]: components["schemas"]["PayloadIndexInfo"] | undefined;
//    };
//}
///**
// * @description Type of segment
// * @enum {string}
// */
//enum SegmentType: String {
//    case plain
//    case indexed
//    case special
//}
//struct SegmentConfig {
//    let vector_data: {
//        [key: string]: components["schemas"]["VectorDataConfig"] | undefined;
//    };
//    let payload_storage_type: PayloadStorageType
//}
///** @description Config of single vector data storage */
//struct VectorDataConfig {
//    /**
//     * Format: uint
//     * @description Size/dimensionality of the vectors used
//     */
//    let size: UInt
//    let distance: Distance
//    let storage_type: VectorStorageType
//    let index: Indexes
//    /** @description Vector specific quantization config that overrides collection config */
//    let quantization_config: QuantizationConfig?
//};
///** @description Storage types for vectors */
//enum VectorStorageType: String {
//    case memory = "Memory"
//    case mmap = "Mmap"
//    case chunkedMmap = "ChunkedMmap"
//}
///** @description Vector index configuration */
//Indexes: OneOf<[{
//    /** @enum {string} */
//type: "plain";
//options: Record<string, never>;
//}, {
//    /** @enum {string} */
//type: "hnsw";
//options: components["schemas"]["HnswConfig"];
//}]>;
///** @description Type of payload storage */
//enum PayloadStorageType: String {
//    case in_memory
//    case on_disk
//}
//struct VectorIndexSearchesTelemetry {
//    let index_name: String?
//    let unfiltered_plain: OperationDurationStatistics
//    let unfiltered_hnsw: OperationDurationStatistics
//    let filtered_plain: OperationDurationStatistics
//    let filtered_small_cardinality: OperationDurationStatistics
//    let filtered_large_cardinality: OperationDurationStatistics
//    let filtered_exact: OperationDurationStatistics
//    let unfiltered_exact: OperationDurationStatistics
//}
//struct OperationDurationStatistics {
//    /** Format: uint */
//    let count: UInt
//    /** Format: uint */
//    let fail_count: UInt?
//    /** Format: float */
//    let avg_duration_micros: Float?
//    /** Format: float */
//    let min_duration_micros: Float?
//    /** Format: float */
//    let max_duration_micros: Float?
//    /** Format: date-time */
//    let last_responded: String?
//}
//struct PayloadIndexTelemetry {
//    let field_name: String?
//    /** Format: uint */
//    let points_values_count: UInt
//    /** Format: uint */
//    let points_count: UInt
//    /** Format: uint */
//    let histogram_bucket_size: UInt?
//}
//struct OptimizerTelemetry {
//    let status: OptimizersStatus
//    let optimizations: OperationDurationStatistics
//}
//struct RemoteShardTelemetry {
//    /** Format: uint32 */
//    let shard_id: UInt32
//    /** Format: uint64 */
//    let peer_id: UInt64?
//    let searches: OperationDurationStatistics
//    let updates: OperationDurationStatistics
//};
//struct CollectionsAggregatedTelemetry {
//    /** Format: uint */
//    let vectors: UInt
//    let optimizers_status: OptimizersStatus
//    let params: CollectionParams
//};
//struct ClusterTelemetry {
//    let enabled: Bool
//    let status: ClusterStatusTelemetry?
//    let config: ClusterStatusTelemetry?
//};
//struct ClusterStatusTelemetry {
//    /** Format: uint */
//    let number_of_peers: UInt
//    /** Format: uint64 */
//    let term: UInt64
//    /** Format: uint64 */
//    let commit: UInt64
//    /** Format: uint */
//    let pending_operations: number;
//    let role: StateRole?
//    let is_voter: Bool
//    /** Format: uint64 */
//    let peer_id: UInt64?
//    let consensus_thread_status: ConsensusThreadStatus
//};
//struct ClusterConfigTelemetry {
//    /** Format: uint64 */
//    let grpc_timeout_ms: UInt64
//    let p2p: P2pConfigTelemetry
//    let consensus: ConsensusConfigTelemetry
//}
//struct P2pConfigTelemetry {
//    /** Format: uint */
//    let connection_pool_size: UInt
//}
//struct ConsensusConfigTelemetry {
//    /** Format: uint */
//    let max_message_queue_size: UInt
//    /** Format: uint64 */
//    let tick_period_ms: UInt64
//    /** Format: uint64 */
//    let bootstrap_timeout_sec: UInt64
//}
//struct RequestsTelemetry {
//    let rest: WebApiTelemetry
//    let grpc: GrpcTelemetry
//}
//struct WebApiTelemetry {
//    let responses: {
//        [key: string]: ({
//            [key: string]: components["schemas"]["OperationDurationStatistics"] | undefined;
//        }) | undefined;
//    };
//};
//struct GrpcTelemetry {
//    let responses: {
//        [key: string]: components["schemas"]["OperationDurationStatistics"] | undefined;
//    };
//};
//ClusterOperations: components["schemas"]["MoveShardOperation"] | components["schemas"]["ReplicateShardOperation"] | components["schemas"]["AbortTransferOperation"] | components["schemas"]["DropReplicaOperation"];
//struct MoveShardOperation {
//    let move_shard: MoveShard
//}
//struct MoveShard {
//    /** Format: uint32 */
//    let shard_id: UInt32
//    /** Format: uint64 */
//    let to_peer_id: UInt64
//    /** Format: uint64 */
//    let from_peer_id: UInt64
//}
//struct ReplicateShardOperation {
//    let replicate_shard: MoveShard
//}
//struct AbortTransferOperation {
//    let abort_transfer: MoveShard
//}
//struct DropReplicaOperation {
//    let drop_replica: Replica
//}
//struct Replica {
//    /** Format: uint32 */
//    let shard_id: UInt32
//    /** Format: uint64 */
//    let peer_id: UInt64
//};
//struct SearchRequestBatch {
//    let searches: [SearchRequest]
//}
//struct RecommendRequestBatch {
//    let searches: [RecommendRequest]
//}
//struct LocksOption {
//    let error_message: String
//    let write: Bool
//}
//struct SnapshotRecover {
//    /**
//     * Format: uri
//     * @description Examples: - URL `http://localhost:8080/collections/my_collection/snapshots/my_snapshot` - Local path `file:///qdrant/snapshots/test_collection-2022-08-04-10-49-10.snapshot`
//     */
//    let location: String
//    /**
//     * @description Defines which data should be used as a source of truth if there are other replicas in the cluster. If set to `Snapshot`, the snapshot will be used as a source of truth, and the current state will be overwritten. If set to `Replica`, the current state will be used as a source of truth, and after recovery if will be synchronized with the snapshot.
//     * @default null
//     */
//    let priority: SnapshotPriority?
//}
///**
// * @description Defines source of truth for snapshot recovery
// * - `Snapshot`: prefer snapshot data over the current state
// * - `Replica`: prefer existing data over the snapshot
// * @enum {string}
// */
//enum SnapshotPriority: String {
//    /// prefer snapshot data over the current state
//    case snapshot
//    /// prefer existing data over the snapshot
//    case replica
//}
//struct CollectionsAliasesResponse {
//    let aliases: [AliasDescription]
//}
//struct AliasDescription {
//    let alias_name: String
//    let collection_name: String
//}
///**
// * @description Defines write ordering guarantees for collection operations
// *
// * * `weak` - write operations may be reordered, works faster, default
// *
// * * `medium` - write operations go through dynamically selected leader, may be inconsistent for a short period of time in case of leader change
// *
// * * `strong` - Write operations go through the permanent leader, consistent, but may be unavailable if leader is down
// * @enum {string}
// */
public enum QTWriteOrdering: String {
    case weak
    case medium
    case strong
}
/**
 * @description Read consistency parameter
 *
 * Defines how many replicas should be queried to get the result
 *
 * * `N` - send N random request and return points, which present on all of them
 *
 * * `majority` - send N/2+1 random request and return points, which present on all of them
 *
 * * `quorum` - send requests to all nodes and return points which present on majority of them
 *
 * * `all` - send requests to all nodes and return points which present on all of them
 *
 * Default value is `Factor(1)`
 */
/**
 * @description * `majority` - send N/2+1 random request and return points, which present on all of them
 *
 * * `quorum` - send requests to all nodes and return points which present on majority of nodes
 *
 * * `all` - send requests to all nodes and return points which present on all nodes
 * @enum {string}
 */
public enum ReadConsistency {
    case number(UInt)
    case majority
    case quorum
    case all
    
    var query: String {
        switch self {
        case .number(let int):
            return "consistency=\(int)"
        case .majority:
            return "consistency=majority"
        case .quorum:
            return "consistency=quorum"
        case .all:
            return "consistency=all"
        }
    }
}

//struct UpdateVectors {
//    /** @description Points with named vectors */
//    let points: [PointVectors]
//}
//struct PointVectors {
//    let id: ExtendedPointId
//    let vector: VectorStruct
//}
//struct DeleteVectors {
//    /** @description Deletes values from each point in this list */
//    let points: [ExtendedPointId]?
//    /** @description Deletes values from points that satisfy this filter condition */
//    let filter: Filter?
//    /** @description Vector names */
//    let vector: [String]
//}
//struct PointGroup {
//    /** @description Scored points that have the same value of the group_by key */
//    let hits: [ScoredPoint]
//    let id: GroupId
//}
//GroupId: string | number;
//struct SearchGroupsRequest {
//    let vector: NamedVectorStruct
//    /** @description Look only for points which satisfies this conditions */
//    let filter: Filter?
//    /** @description Additional search params */
//    let params: SearchParams?
//    /** @description Select which payload to return with the response. Default: None */
//    let with_payload: WithPayloadInterface?
//    /**
//     * @description Whether to return the point vector with the result?
//     * @default null
//     */
//    let with_vector: WithVector?
//    /**
//     * Format: float
//     * @description Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
//     */
//    let score_threshold: Float?
//    /** @description Payload field to group by, must be a string or number field. If the field contains more than 1 value, all values will be used for grouping. One point can be in multiple groups. */
//    let group_by: String
//    /**
//     * Format: uint32
//     * @description Maximum amount of points to return per group
//     */
//    let group_size: UInt32
//    /**
//     * Format: uint32
//     * @description Maximum amount of groups to return
//     */
//    let  limit: UInt32
//}
//struct RecommendGroupsRequest {
//    /** @description Look for vectors closest to those */
//    let positive: [ExtendedPointId]
//    /**
//     * @description Try to avoid vectors like this
//     * @default []
//     */
//    let negative: [ExtendedPointId]?
//    /** @description Look only for points which satisfies this conditions */
//    let filter: Filter?
//    /** @description Additional search params */
//    let params: SearchParams?
//    /** @description Select which payload to return with the response. Default: None */
//    let with_payload: WithPayloadInterface?
//    /**
//     * @description Whether to return the point vector with the result?
//     * @default null
//     */
//    let with_vector: WithVector?
//    /**
//     * Format: float
//     * @description Define a minimal score threshold for the result. If defined, less similar results will not be returned. Score of the returned result might be higher or smaller than the threshold depending on the Distance function used. E.g. for cosine similarity only higher scores will be returned.
//     */
//    let score_threshold: Float?
//    /**
//     * @description Define which vector to use for recommendation, if not specified - try to use default vector
//     * @default null
//     */
//    let using: UsingVector?
//    /**
//     * @description The location used to lookup vectors. If not specified - use current collection. Note: the other collection should have the same vector size as the current collection
//     * @default null
//     */
//    let lookup_from: LookupLocation?
//    /** @description Payload field to group by, must be a string or number field. If the field contains more than 1 value, all values will be used for grouping. One point can be in multiple groups. */
//    let group_by: String
//    /**
//     * Format: uint32
//     * @description Maximum amount of points to return per group
//     */
//    let group_size: UInt32
//    /**
//     * Format: uint32
//     * @description Maximum amount of groups to return
//     */
//    let limit: UInt32
//}
//struct GroupsResult {
//    let groups: [PointGroup]
//}
//
