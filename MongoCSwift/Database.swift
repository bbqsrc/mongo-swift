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

public class Database {
    internal let handle: COpaquePointer
    
    public var name: String {
        return NSString(UTF8String: mongoc_database_get_name(self.handle)) as! String
    }
    
    internal init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_database_destroy(handle)
    }
    
    func getCollection(collection: String) -> Collection {
        return Collection(handle: mongoc_database_get_collection(handle, utf8(collection)))
    }
    
    func dropCollection(collection: Collection) throws {
        try mongoCall { err in
            return mongoc_collection_drop(collection.handle, err)
        }
    }
    
    /*
    func dropCollection(name: String) throws {
        try mongoCall { err in
            return mongoc_database_has_collection(self.handle, utf8(name), err) {
                try self.dropCollection(self.getCollection(name))
            }
        }
    }
    */
    
    subscript(collection: String) -> Collection {
        return getCollection(collection)
    }
}