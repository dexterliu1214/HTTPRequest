//
//  HTTPRequestable.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/6/29.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation
import UIKit

public enum HTTPRequestableError:Error{
    case url
    case server(Error)
    case parse
}

public protocol HTTPRequestable
{
    func get<T:Requestable>(_ request:T) -> Result<T.Responsable, HTTPRequestableError>
    func post<T:PostRequestable>(_ request:T) -> Result<T.Responsable, HTTPRequestableError>
}

public extension HTTPRequestable
{
    func get<T:Requestable>(_ request:T) -> Result<T.Responsable, HTTPRequestableError> {
        guard var uc = URLComponents(string: request.url) else {
            return .failure(.url)
        }
        uc.queryItems = request.queryItems
        var result: Result<T.Responsable, HTTPRequestableError>!
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
                let obj = try JSONDecoder().decode(T.Responsable.self, from: data)
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
    
    func post<T:PostRequestable>(_ request:T) -> Result<T.Responsable, HTTPRequestableError> {
        guard let url = URL(string: request.url) else {
            return .failure(.url)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let boundary = UUID().uuidString
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = request.body(boundary:boundary)
        var result: Result<T.Responsable, HTTPRequestableError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.uploadTask(with: urlRequest, from: body) { data, response, error in
            print(request.url)
            if let error = error {
                result = .failure(.server(error))
                return
            }
            
            guard let data = data else { return }
            if let jsonString = data.jsonString {
                print(jsonString)
            }
            guard let json = try? JSONDecoder().decode(T.Responsable.self, from: data) else {
                print(String(data: data, encoding: .utf8)!)
                result = .failure(.parse)
                return
            }
            result = .success(json)
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
}
