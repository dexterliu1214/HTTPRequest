//
//  APIRequest.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/7/3.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation
import UIKit

public protocol Requestable {
    associatedtype Responsable: Decodable
    var url:String { get }
    var queryItems:[URLQueryItem] { get }
    func body(boundary:String) -> Data
    func get() -> Result<Responsable, HTTPRequestError>
    func post() -> Result<Responsable, HTTPRequestError>
}

public extension Requestable
{
    var queryItems:[URLQueryItem] {
        Mirror(reflecting: self).children.map{
            URLQueryItem(name: $0.label!, value: ($0.value as! String))
        }
    }
    
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
    
    func post() -> Result<Responsable, HTTPRequestError> {
        guard let url = URL(string: url) else {
            return .failure(.url)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let boundary = UUID().uuidString
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let bodyData = body(boundary:boundary)
        var result: Result<Responsable, HTTPRequestError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.uploadTask(with: urlRequest, from: bodyData) { data, response, error in
            print(url)
            if let error = error {
                result = .failure(.server(error))
                return
            }
            
            guard let data = data else { return }
            if let jsonString = data.jsonString {
                print(jsonString)
            }
            guard let json = try? JSONDecoder().decode(Responsable.self, from: data) else {
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
