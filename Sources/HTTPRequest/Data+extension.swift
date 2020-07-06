//
//  File.swift
//  
//
//  Created by youga on 2020/7/6.
//

import Foundation

extension Data {
    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
    
    var jsonString:String? {
        do {
            let jsonObject =  try JSONSerialization.jsonObject(with: self)
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data:data, encoding:.utf8)
        } catch {
            return nil
        }
    }
}
