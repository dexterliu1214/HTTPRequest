//
//  HTTPRequestable.swift
//  ios-webrtc-client
//
//  Created by youga on 2020/6/29.
//  Copyright © 2020 dexterliu1214. All rights reserved.
//

import Foundation
import UIKit

public enum HTTPRequestError:Error{
    case url
    case server(Error)
    case parse
}
