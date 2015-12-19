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
    
    func testMongoClient() {
        let _ = MongoClient("mongodb://localhost:27017")
    }
    
    func testMongoClientGetDatabase() {
        let client = MongoClient("mongodb://localhost:27017")
        let db = client.getDatabase("__testDatabase")
        XCTAssertEqual(db.name, "__testDatabase")
    }
    
    func testMongoClientGetCollection() {
        let client = MongoClient("mongodb://localhost:27017")
        let coll = client.getCollection(db: "__testDatabase", collection: "test")
        XCTAssertEqual(coll.name, "test")
    }
    
    func testMongoClientSubscript() {
        let client = MongoClient("mongodb://localhost:27017")
        let db = client["__testDatabase"]
        XCTAssertEqual(db.name, "__testDatabase")
    }
}
