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

public class MongoClient {
    internal let handle: COpaquePointer
    
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
    
    subscript(db: String) -> Database {
        return getDatabase(db)
    }
}
