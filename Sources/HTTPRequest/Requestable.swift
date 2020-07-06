//
//  APIRequest.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/7/3.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation

public protocol Requestable {
    associatedtype Responsable: Decodable
    var queryItems:[URLQueryItem] { get }
    var url:String { get }
}

public extension Requestable
{
    public var queryItems:[URLQueryItem] {
        Mirror(reflecting: self).children.map{
            URLQueryItem(name: $0.label!, value: ($0.value as! String))
        }
    }
}
