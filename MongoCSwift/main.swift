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

mongoc_init()

let client = MongoClient("mongodb://localhost:27017")
let coll = client.getCollection(db: "test", collection: "test")
let yey = try coll.find(q(["test": true]), fields: nil)

let test = try MutableBson(["test": true, "test2": Int64(42)]) as Bson

print(test.get("test")!)

print("IT BEGINS")

for c in yey {
    if let r = c.toJsonString() {
        print(r)
    }
}

try coll.find(q(["test": true]), fields: nil) { c in
    if let r = c.toJsonString() {
        print(r)
    }
}

print(try coll.count(["test": true], skip: 1))
