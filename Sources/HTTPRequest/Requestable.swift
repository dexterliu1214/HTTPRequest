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
    func get() -> Result<Responsable, HTTPRequestError>
}

public extension Requestable
{
    var queryItems:[URLQueryItem] {
        Mirror(reflecting: self).children.map{
            URLQueryItem(name: $0.label!, value: ($0.value as! String))
        }
    }
}

public extension Requestable
{
    func get() -> Result<Responsable, HTTPRequestError> {
        guard var uc = URLComponents(string: url) else {
            return .failure(.url)
        }
        uc.queryItems = queryItems
        var result: Result<Responsable, HTTPRequestError>!
        guard let url = uc.url else { return  .failure(.url) }
        let semaphore = DispatchSemaphore(value: 0)
        print(url.absoluteURL)
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                result = .failure(.server(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let obj = try JSONDecoder().decode(Responsable.self, from: data)
                result = .success(obj)
            } catch {
                if let jsonString = data.jsonString {
                    print(jsonString)
                }
                result = .failure(.parse)
            }
            
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
}
