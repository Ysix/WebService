//
//  WebResource.swift
//  WebServices
//
//  Created by Eddy Claessens on 07/11/2017.
//

import Foundation
import Alamofire

public struct WebResource<A> {
    let url: URL
    let parseJSON: (AnyObject) throws -> (A)
    var method: Alamofire.HTTPMethod = .get
    var parameters: JSONDictionary? = nil
    var headers: [String:String]? = nil

    public var parseJSONError : ((AnyObject) throws -> (NetworkingError.NetworkingErrorInfo?))? = nil

    public init(endPoint: URL,
         method: Alamofire.HTTPMethod = .get,
         parameters: JSONDictionary? = nil,
         headers: [String:String]? = nil,
         parseJSON: @escaping (AnyObject) throws -> (A)) {
        self.url = endPoint
        self.parseJSON = parseJSON
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
}
