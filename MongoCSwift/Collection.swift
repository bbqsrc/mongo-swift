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

enum MongoError: ErrorType {
    case InsertError(message: String)
    case UpdateError(message: String)
    case RemoveError(message: String)
    case CountError(message: String)
}

class Collection {
    internal let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_collection_destroy(handle)
    }
    
    func find(query: Bson, fields: Bson) throws -> Cursor {
        return Cursor(handle: mongoc_collection_find(handle, MONGOC_QUERY_NONE, 0, 0, 0, query.handle, fields.handle, nil))
    }
    
    func insert(document: Bson, flags: mongoc_insert_flags_t=MONGOC_INSERT_NONE/*, writeConcern: Int32=MONGOC_WRITE_CONCERN_W_DEFAULT*/) throws {
        let error = UnsafeMutablePointer<bson_error_t>.alloc(1)
        defer {
            error.destroy()
        }
        
        if !mongoc_collection_insert(handle, flags, document.handle, nil, error) {
            throw MongoError.InsertError(message: errorString(error.memory))
        }
    }
    
    func update(selector: Bson, update: Bson) throws {
        let error = UnsafeMutablePointer<bson_error_t>.alloc(1)
        defer {
            error.destroy()
        }
        
        if !mongoc_collection_update(handle, MONGOC_UPDATE_NONE, selector.handle, update.handle, nil, error) {
            throw MongoError.UpdateError(message: errorString(error.memory))
        }
    }
    
    func remove(selector: Bson) throws {
        let error = UnsafeMutablePointer<bson_error_t>.alloc(1)
        defer {
            error.destroy()
        }

        if !mongoc_collection_remove(handle, MONGOC_REMOVE_NONE, selector.handle, nil, error) {
            throw MongoError.RemoveError(message: errorString(error.memory))
        }
    }
    
    func count(query: Bson, skip: Int64=0, limit: Int64=0) throws -> Int64 {
        let error = UnsafeMutablePointer<bson_error_t>.alloc(1)
        defer {
            error.destroy()
        }
        
        let c = mongoc_collection_count(handle, MONGOC_QUERY_NONE, query.handle, skip, limit, nil, error)
        if c < 0 {
            throw MongoError.CountError(message: errorString(error.memory))
        }
        
        return c
    }
    
    // Convenience overloads
    func find(query: DictionaryLiteral<String, Any>, fields: DictionaryLiteral<String, Any>?=nil) throws -> Cursor {
        return try find(q(query), fields: q(fields))
    }
    
    func find(query: DictionaryLiteral<String, Any>, fields: DictionaryLiteral<String, Any>?=nil, @noescape closure: (bson: Bson) -> Void) throws {
        return try find(q(query), fields: q(fields), closure: closure)
    }
    
    func find(query: [String: Any]?, fields: [String: Any]?=nil) throws -> Cursor {
        let bsonQuery = try MutableBson(query) as Bson
        let bsonFields = try MutableBson(fields) as Bson
        
        return try find(bsonQuery, fields: bsonFields)
    }
    
    func find(query: [String: Any]?, fields: [String: Any]?=nil, @noescape closure: (bson: Bson) -> Void) throws {
        let cur = try find(query, fields: fields)
        for c in cur {
            closure(bson: c)
        }
    }
    
    func update(selector: [String: Any]?, update: [String: Any]?) throws {
        let sel = try MutableBson(selector) as Bson
        let upd = try MutableBson(update) as Bson
        
        try self.update(sel, update: upd)
    }
    
    func update(selector: DictionaryLiteral<String, Any>, update: DictionaryLiteral<String, Any>) throws {
        try self.update(q(selector), update: q(update))
    }
    
    func remove(selector: [String: Any]?) throws {
        let bsonSel = try MutableBson(selector) as Bson
        
        try self.remove(bsonSel)
    }
    
    func remove(selector: DictionaryLiteral<String, Any>) throws {
        try self.remove(q(selector))
    }
    
    func count(query: [String: Any]?, skip: Int64=0, limit: Int64=0) throws -> Int64 {
        let bsonQuery = try MutableBson(query) as Bson
        
        return try count(bsonQuery, skip: skip, limit: limit)
    }
    
    func count(query: DictionaryLiteral<String, Any>, skip: Int64=0, limit: Int64=0) throws -> Int64 {
        return try count(q(query), skip: skip, limit: limit)
    }
}