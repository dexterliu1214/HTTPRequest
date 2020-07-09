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
    func post() -> Result<Responsable, HTTPRequestError>
}

public extension PostRequestable {
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
