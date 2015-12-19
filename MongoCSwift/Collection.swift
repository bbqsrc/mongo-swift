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

public enum MongoError: ErrorType {
    case UnknownError(code: UInt32, domain: UInt32, message: String)
    case InsertError(message: String)
    case UpdateError(message: String)
    case RemoveError(message: String)
    case CountError(message: String)
}

public class Collection {
    internal let handle: COpaquePointer
    
    public var name: String {
        return NSString(UTF8String: mongoc_collection_get_name(self.handle)) as! String
    }
    
    internal init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_collection_destroy(handle)
    }
    
    func find(query: Bson, fields: Bson=Bson.empty) -> Cursor {
        return Cursor(handle: mongoc_collection_find(handle, MONGOC_QUERY_NONE, 0, 0, 0, query.handle, fields.handle, nil))
    }
    
    func find(query: Bson, fields: Bson=Bson.empty, @noescape closure: (bson: Bson) -> Void) {
        let cur = find(query, fields: fields)
        for c in cur {
            closure(bson: c)
        }
    }
    
    func findOne(query: Bson, fields: Bson=Bson.empty) -> Bson? {
        let cur = find(query, fields: fields)
        return cur.next()
    }
    
    func insert(documents: [Bson], flags: mongoc_insert_flags_t=MONGOC_INSERT_NONE) throws -> Result {
        let bulk = mongoc_collection_create_bulk_operation(handle, true, nil)
        let error = UnsafeMutablePointer<bson_error_t>.alloc(1)
        let reply = UnsafeMutablePointer<bson_t>.alloc(1)
        
        defer {
            mongoc_bulk_operation_destroy(bulk)
            bson_destroy(reply)
            reply.destroy()
            error.destroy()
        }
        
        for doc in documents {
            mongoc_bulk_operation_insert(bulk, doc.handle)
        }
        
        let res = mongoc_bulk_operation_execute(bulk, reply, error)
        if res == 0 {
            throw MongoError.InsertError(message: errorString(error.memory))
        }
        
        return Result(handle: reply)
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
}