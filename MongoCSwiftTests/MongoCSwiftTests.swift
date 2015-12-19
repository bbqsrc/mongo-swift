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

import XCTest
@testable import MongoCSwift

class MongoCSwiftTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test000MongoInit() {
        // required or nightmares will occur.
        mongoc_init()
    }
    
    func test001MongoClient() {
        let _ = MongoClient("mongodb://localhost:27017")
    }
    
    func test002MongoClientGetDatabase() {
        let client = MongoClient("mongodb://localhost:27017")
        let db = client.getDatabase("__testDatabase")
        XCTAssertEqual(db.name, "__testDatabase")
    }
    
    func test003MongoClientGetCollection() {
        let client = MongoClient("mongodb://localhost:27017")
        let coll = client.getCollection(db: "__testDatabase", collection: "test")
        XCTAssertEqual(coll.name, "test")
    }
    
    func test004MongoClientSubscript() {
        let client = MongoClient("mongodb://localhost:27017")
        let db = client["__testDatabase"]
        XCTAssertEqual(db.name, "__testDatabase")
    }
    
    func test007DropCollection() {
        let client = MongoClient("mongodb://localhost:27017")
        let db = client["__testDatabase"]
        do {
            try db.dropCollection(db.getCollection("test"))
        } catch {
            XCTFail("Drop failed")
        }
    }
    
    func test006CollectionInsert() {
        var doc: Bson;
        do {
            let subdoc: Bson = try bson([
                "a": true,
                "b": 32,
                "c": Int64(64),
                "d": NSDate(),
                "e": "a string"
            ])
            
            doc = try bson(["key": "value", "test": subdoc])
        } catch BsonError.UnsupportedType(let key, let type) {
            XCTFail("\(key): \(type)")
            return
        } catch {
            XCTFail("BSON fail")
            return
        }
        
        do {
            let client = MongoClient("mongodb://localhost:27017")
            let coll = client.getCollection(db: "__testDatabase", collection: "test")
            
            try coll.insert(doc)
        } catch {
            XCTFail("Insert fail")
        }
    }
    
    func test007CollectionFindOne() {
        let client = MongoClient("mongodb://localhost:27017")
        let coll = client.getCollection(db: "__testDatabase", collection: "test")
        
        do {
            let doc = try coll.findOne(bson(["key": "value"]))!
            print(doc.toJsonString()!)
        } catch {
            XCTFail("FindOne fail")
        }
    }
    
    func test008CollectionRemove() {
        let client = MongoClient("mongodb://localhost:27017")
        let coll = client.getCollection(db: "__testDatabase", collection: "test")
        
        do {
            try coll.remove(bson(["key": "value"]))
            if let _ = try coll.findOne(bson(["key": "value"])) {
                XCTFail("Doc found, should be nil")
            }
            
        } catch {
            XCTFail("Delete fail")
        }
    }
}
