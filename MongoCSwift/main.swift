// Copyright © 2015  Brendan Molloy <brendan@bbqsrc.net>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

mongoc_init()

enum BsonError: ErrorType {
    case UnsupportedType(key: String, type: Any.Type)
}

private func utf8(key: String) -> UnsafePointer<Int8> {
    return (key as NSString).UTF8String
}

// Needed to stop booleans being coerced to integers, and NSObjects appearing out of nowhere
func q(x: [String: Any]) -> [String: Any] {
    return x
}

class Bson {
    private let handle: UnsafePointer<bson_t>
    
    private init(handle: UnsafePointer<bson_t>) {
        self.handle = handle
    }
    
    func toJsonString() -> String? {
        let b = bson_as_json(handle, nil)
        defer {
            bson_free(b)
        }
        
        return String(CString: b, encoding: NSUTF8StringEncoding)
    }
}

class MutableBson : Bson {
    private let mutHandle: UnsafeMutablePointer<bson_t>
    
    private init(handle: UnsafeMutablePointer<bson_t>) {
        self.mutHandle = handle
        super.init(handle: UnsafePointer<bson_t>.init(handle))
    }
    
    convenience private init() {
        self.init(handle: bson_new())
    }
    
    deinit {
        bson_destroy(mutHandle)
    }
    
    func append(key: String, string val: String) {
        bson_append_utf8(mutHandle, utf8(key), -1, utf8(val), -1)
    }
    
    func append(key: String, int32 val: Int32) {
        bson_append_int32(mutHandle, utf8(key), -1, val)
    }
    
    func append(key: String, int64 val: Int64) {
        bson_append_int64(mutHandle, utf8(key), -1, val)
    }
    
    func append(key: String, double val: Double) {
        bson_append_double(mutHandle, utf8(key), -1, val)
    }
    
    func append(key: String, bool val: Bool) {
        bson_append_bool(mutHandle, utf8(key), -1, val)
    }
    
    func append(key: String, array val: [Any]) throws {
        let array = MutableBson()
        bson_append_array_begin(mutHandle, utf8(key), -1, array.mutHandle)
        
        for (i, v) in val.enumerate() {
            let k = String(i)
            
            do {
                switch v {
                case is String:
                    array.append(k, string: v as! String)
                case is Double:
                    array.append(k, double: v as! Double)
                case is Bool:
                    array.append(k, bool: v as! Bool)
                case is Int32:
                    array.append(k, int32: v as! Int32)
                case is Int64:
                    array.append(k, int64: v as! Int64)
                case let vv as [Any]:
                    try array.append(k, array: vv)
                case let vv as [String: Any]:
                    try array.append(k, document: vv)
                default:
                    throw BsonError.UnsupportedType(key: k, type: v.dynamicType)
                }
            } catch {
                throw BsonError.UnsupportedType(key: k, type: v.dynamicType)
            }
        }
        
        bson_append_array_end(mutHandle, array.mutHandle)
    }
    
    func append(key: String, document val: [String: Any]) throws {
        let bsonDoc = try MutableBson(val)
        bson_append_document(mutHandle, utf8(key), -1, bsonDoc.mutHandle)
    }
    
    func append(key: String, timestamp val: NSDate) {
        let ts = Int64(val.timeIntervalSince1970 * 1000.0)
        bson_append_date_time(mutHandle, utf8(key), -1, ts)
    }
    
    convenience init(_ val: [String: Any]?) throws {
        self.init()
        
        guard val != nil else {
            return
        }
        
        for (k, v) in val! {
            do {
                switch v {
                case is String:
                    append(k, string: v as! String)
                case is Double:
                    append(k, double: v as! Double)
                case is Bool:
                    append(k, bool: v as! Bool)
                case is Int32:
                    append(k, int32: v as! Int32)
                case is Int64:
                    append(k, int64: v as! Int64)
                case let vv as [Any]:
                    try append(k, array: vv)
                case let vv as [String: Any]:
                    try append(k, document: vv)
                default:
                    throw BsonError.UnsupportedType(key: k, type: v.dynamicType)
                }
            } catch {
                throw BsonError.UnsupportedType(key: k, type: v.dynamicType)
            }
        }
    }
}


class Cursor : SequenceType, GeneratorType {
    private let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_cursor_destroy(handle)
    }
    
    func generate() -> Cursor.Generator {
        return self
    }
    
    func next() -> Bson? {
        var b = UnsafeMutablePointer<UnsafePointer<bson_t>>.alloc(1)
        
        defer {
            b.destroy()
        }
        
        let res = mongoc_cursor_next(handle, b)
        
        if res == false {
            return nil
        }
        
        return Bson(handle: UnsafeMutablePointer<bson_t>(b.memory))
    }
}


class Database {
    private let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_database_destroy(handle)
    }
}


class Collection {
    private let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_collection_destroy(handle)
    }
    
    func find(query: [String: Any]?, fields: [String: Any]?) throws -> Cursor {
        let bsonQuery = try MutableBson(query) as Bson
        let bsonFields = try MutableBson(fields) as Bson
        
        return Cursor(handle: mongoc_collection_find(handle, MONGOC_QUERY_NONE, 0, 0, 0, bsonQuery.handle, bsonFields.handle, nil))
    }
}


class MongoClient {
    private let handle: COpaquePointer
    
    init(_ uri: String) {
        self.handle = mongoc_client_new(utf8(uri))
    }
    
    deinit {
        mongoc_client_destroy(handle)
    }
    
    func getDatabase(db: String) -> Database {
        return Database(handle: mongoc_client_get_database(handle, utf8(db)))
    }
    
    func getCollection(db db: String, collection: String) -> Collection {
        return Collection(handle: mongoc_client_get_collection(handle, utf8(db), utf8(collection)))
    }
}

print(true.dynamicType.dynamicType)
let client = MongoClient("mongodb://localhost:27017")
let coll = client.getCollection(db: "test", collection: "test")
let yey = try coll.find(q(["test": true]), fields: nil)

print("IT BEGINS")

for c in yey {
    if let r = c.toJsonString() {
        print(r)
    }
}
