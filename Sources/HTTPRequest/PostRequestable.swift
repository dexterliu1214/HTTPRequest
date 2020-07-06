//
//  PostRequestable.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/7/6.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation
import UIKit

public protocol PostRequestable {
    associatedtype Responsable: Decodable
    func body(boundary:String) -> Data
    var url:String { get }
}

extension PostRequestable {
    func body(boundary:String) -> Data {
        var data = Data()
        Mirror(reflecting: self).children.forEach{
            data.appendString(string: "--\(boundary)\r\n")
            if let image = $0.value as? UIImage {
                data.appendString(string: "Content-Disposition: form-data; name=\"\($0.label!)\"; filename=\"\(arc4random()).jpg\"\r\n")
                data.appendString(string: "Content-Type: image/jpeg\r\n\r\n")
                data.append(image.jpegData(compressionQuality: 1)!)
                data.appendString(string: "\r\n")
            } else {
                data.appendString(string: "Content-Disposition: form-data; name=\"\($0.label!)\"\r\n\r\n")
                data.appendString(string: "\(($0.value as! String))\r\n")
            }
        }
        data.appendString(string: "--\(boundary)--\r\n")
        return data
    }
}
