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

class Cursor : SequenceType, GeneratorType {
    internal let handle: COpaquePointer
    
    init(handle: COpaquePointer) {
        self.handle = handle
    }
    
    deinit {
        mongoc_cursor_destroy(handle)
    }
    
    func generate() -> Cursor.Generator {
        return self
    }
    
    func next() -> Bson? {
        var b = UnsafeMutablePointer<UnsafePointer<bson_t>>.alloc(1)
        
        defer {
            b.destroy()
        }
        
        let res = mongoc_cursor_next(handle, b)
        
        if res == false {
            return nil
        }
        
        return Bson(handle: UnsafeMutablePointer<bson_t>(b.memory))
    }
}