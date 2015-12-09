//
// This file is part of mongo-swift.
//
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
//

import Foundation

enum BsonError: ErrorType {
    case UnsupportedType(key: String, type: Any.Type)
}

class Bson {
    internal let handle: UnsafePointer<bson_t>
    
    internal init(handle: UnsafePointer<bson_t>) {
        self.handle = handle
    }
    
    func toJsonString() -> String? {
        let b = bson_as_json(handle, nil)
        defer {
            bson_free(b)
        }
        
        return String(CString: b, encoding: NSUTF8StringEncoding)
    }
    
    func get<T>(key: String) -> T? {
        let iter = UnsafeMutablePointer<bson_iter_t>.alloc(1)
        let desc = UnsafeMutablePointer<bson_iter_t>.alloc(1)
        
        defer {
            bson_free(iter)
            bson_free(desc)
        }
        
        bson_iter_init(iter, handle)
        if bson_iter_find_descendant(iter, utf8(key), desc) {
            let type = bson_iter_type(desc)
            
            var res: Any
            
            switch type {
            case BSON_TYPE_BOOL:
                res = bson_iter_bool(desc)
            case BSON_TYPE_DATE_TIME:
                res = NSDate(timeIntervalSince1970: Double(bson_iter_date_time(desc)))
            case BSON_TYPE_INT32:
                res = bson_iter_int32(desc)
            case BSON_TYPE_INT64:
                res = bson_iter_int64(desc)
            case BSON_TYPE_UTF8:
                res = bson_iter_utf8(desc, nil)
            default:
                return nil
            }
            
            if let out = res as? T {
                return out
            }
        }
        
        return nil
    }
}


class MutableBson : Bson {
    internal let mutHandle: UnsafeMutablePointer<bson_t>
    
    internal init(handle: UnsafeMutablePointer<bson_t>) {
        self.mutHandle = handle
        super.init(handle: UnsafePointer<bson_t>.init(handle))
    }
    
    convenience internal init() {
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
    
    convenience init(_ val: DictionaryLiteral<String, Any>) throws {
        try self.init(q(val))
    }
}