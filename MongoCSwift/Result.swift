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

struct Result {
    var inserted: UInt64
    var matched: UInt64
    var modified: UInt64
    var removed: UInt64
    var upserted: UInt64
    var writeErrors: [Bson]?
    var writeConcernErrors: [Bson]?
    
    internal init(handle: UnsafePointer<bson_t>) {
        let bson = Bson(handle: handle)
        inserted = bson.get("nInserted") ?? 0
        matched = bson.get("nMatched") ?? 0
        modified = bson.get("nModified") ?? 0
        removed = bson.get("nRemoved") ?? 0
        upserted = bson.get("nUpserted") ?? 0
        
        /*
        if let x = bson.get("writeErrors") {
            writeErrors = Bson(handle: x)
        }
        
        if let x = bson.get("writeConcernErrors") {
            writeConcernErrors = Bson(handle: x)
        }
        */
    }
}