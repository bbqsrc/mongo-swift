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

internal func utf8(key: String) -> UnsafePointer<Int8> {
    return (key as NSString).UTF8String
}

// Needed to stop booleans being coerced to integers, and NSObjects appearing out of nowhere
internal func q(x: [String: Any]) -> [String: Any] {
    return x
}

internal func q(x: DictionaryLiteral<String, Any>?) -> [String: Any] {
    var out = [String: Any]()
    
    if x == nil {
        return [:]
    }
    
    for (k, v) in x! {
        if let vv = v as? DictionaryLiteral<String, Any> {
            out[k] = q(vv)
        } else {
            out[k] = v
        }
        
    }
    
    return out
}
