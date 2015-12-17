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

class Collection {
    internal let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_collection_destroy(handle)
    }
    
    func find(query: [String: Any]?, fields: [String: Any]?=nil) throws -> Cursor {
        let bsonQuery = try MutableBson(query) as Bson
        let bsonFields = try MutableBson(fields) as Bson
        
        return Cursor(handle: mongoc_collection_find(handle, MONGOC_QUERY_NONE, 0, 0, 0, bsonQuery.handle, bsonFields.handle, nil))
    }
    
    
    func find(query: [String: Any]?, fields: [String: Any]?=nil, @noescape closure: (bson: Bson) -> Void) throws {
        let cur = try find(query, fields: fields)
        for c in cur {
            closure(bson: c)
        }
    }
    
    // Convenience overloads
    func find(query: DictionaryLiteral<String, Any>, fields: DictionaryLiteral<String, Any>?=nil) throws -> Cursor {
        return try find(q(query), fields: q(fields))
    }
    
    func find(query: DictionaryLiteral<String, Any>, fields: DictionaryLiteral<String, Any>?=nil, @noescape closure: (bson: Bson) -> Void) throws {
        return try find(q(query), fields: q(fields), closure: closure)
    }
}