//
//  APIRequest.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/7/3.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation
import UIKit
import Combine

struct ResponseStatus:Decodable {
    var status:Int
    var err:String?
}

public protocol Requestable {
    static var headers:[String:String] { get }
    associatedtype Responsable: Decodable
    var url:String { get }
    var queryItems:[URLQueryItem] { get }
    func body(boundary:String) -> Data
    func get() -> AnyPublisher<Responsable, URLError>
    func post() -> AnyPublisher<Responsable, URLError>
}

extension String:Error{}
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

public extension Requestable
{
    static var headers:[String:String] { [:] }
    
    var queryItems:[URLQueryItem] {
        Mirror(reflecting: self).children.map{
            URLQueryItem(name: $0.label!, value: ($0.value as! String))
        }
    }
    
    func get() -> AnyPublisher<Responsable, URLError> {
        Future<Responsable, URLError> { promise in
            guard var uc = URLComponents(string: url) else {
                return promise(.failure(URLError(URLError.Code.badURL)))
            }
            uc.queryItems = queryItems
            
            guard let url = uc.url else { return  promise(.failure(URLError(URLError.Code.badURL))) }
        
            print(url.absoluteURL)
            
            var request = URLRequest(url: url)
            Self.headers.forEach { (key, value) in
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            URLSession.shared.dataTask(with: request){ (data, _, error) in
                if let error = error {
                    promise(.failure(URLError.init(URLError.Code.unknown, userInfo: ["info": error.localizedDescription])))
                    return
                }
                guard let data = data else { return }
                
                do {
                    if let jsonString = String(data:data, encoding: .utf8) {
                        if jsonString.contains("\"status\":") {
                            let response = try JSONDecoder().decode(ResponseStatus.self, from: data)
                            if response.status == 0 {
                                promise(.failure(URLError.init(URLError.Code.unknown, userInfo: ["info": response.err ?? "unknow"])))
                                return
                            }
                        }
                    }
                    
                    let obj = try JSONDecoder().decode(Responsable.self, from: data)
                    promise(.success(obj))
                } catch {
                    if let jsonString = data.jsonString {
                        print(jsonString)
                        promise(.failure(URLError.init(URLError.Code.cannotParseResponse, userInfo: ["info": jsonString])))
                    }
                }
            }.resume()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
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
    
    func post() -> AnyPublisher<Responsable, URLError> {
        Future<Responsable, URLError> { promise in
            guard let url = URL(string: url) else {
                return promise(.failure(URLError(URLError.Code.badURL)))
            }
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let boundary = UUID().uuidString
            
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let bodyData = body(boundary:boundary)
            
            URLSession.shared.uploadTask(with: urlRequest, from: bodyData) { data, response, error in
                print(url)
                if let error = error {
                    promise(.failure(URLError(URLError.Code.unknown, userInfo: ["info": error.localizedDescription])))
                    return
                }
                
                guard let data = data else { return }
                if let jsonString = data.jsonString {
                    print(jsonString)
                }
                guard let json = try? JSONDecoder().decode(Responsable.self, from: data) else {
                    let str = String(data: data, encoding: .utf8)!
                    promise(.failure(URLError(URLError.Code.cannotParseResponse, userInfo: ["info": str])))
                    return
                }
                promise(.success(json))
            }.resume()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
