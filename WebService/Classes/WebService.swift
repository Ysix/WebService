//
//  WebServices.swift
//
//
//  Created by Eddy Claessens on 06/11/17.
//  Copyright © 2016 Eddy Claessens. All rights reserved.
//

import Foundation
import Alamofire

public typealias JSONDictionary = [String: AnyObject]

public enum RequestResult<resultType, errorType> {
    case error(errorType)
    case success(resultType)
}

//public struct PaginedResult<resultType> {
//    var result: resultType
//    var currentPage: Int
//    var numberOfPages: Int
//
//    init(result: resultType, currentPage: Int, numberOfPages: Int) {
//        self.result = result
//        self.currentPage = currentPage
//        self.numberOfPages = numberOfPages
//    }
//}

public class WebService {

    public static let shared: WebService = WebService()

    public var debug = false
    public var defaultHeaders: [String:String]? = nil

    public func load<A>(_ resource: WebResource<A>, completion: @escaping (RequestResult<A, NetworkingError>) -> ()) {

        var headers: [String: String]? = nil

        if let defaultHeaders = self.defaultHeaders, self.defaultHeaders!.count > 0 {
            headers = defaultHeaders
            if let resourceHeaders = resource.headers {
                for (key,value) in resourceHeaders {
                    headers![key] = value
                }
            }
        } else {
            headers = resource.headers
        }

        Alamofire.request(resource.url, method: resource.method, parameters: resource.parameters, encoding: resource.method == .get ? URLEncoding.queryString : JSONEncoding.default, headers: headers).validate().responseJSON { (response) -> Void in

            if self.debug {
                let requestId: String = (response.response?.allHeaderFields["X-Request-Id"]) as? String ?? "No Request Id"
                print("[\(requestId)] request \(resource.method) \(resource.url)")
                print("[\(requestId)] headers : \(String(describing: response.request?.allHTTPHeaderFields))")
                print("[\(requestId)] response headers: \(String(describing: response.response?.allHeaderFields))")
                print("[\(requestId)] parameters : \(String(describing: resource.parameters))")
                print("[\(requestId)] response : \(response.result)")
                print("[\(requestId)] statusCode : \(String(describing: response.response?.statusCode))")
            }

            switch response.result {
            case .failure(let error):
                if (error as NSError).domain == NSURLErrorDomain
                    && (error as NSError).code == NSURLErrorNotConnectedToInternet {
                    completion(.error(NetworkingError.notConnectedToInternet))
                    return
                }
                if let statusCode = response.response?.statusCode {
                    var errorInfo : NetworkingError.NetworkingErrorInfo? = nil
                    if let errorParser = resource.parseJSONError, // if no parser error, don't bother to extract the json from the resource.
                        let data = response.data,
                        let errorJson = try? JSONSerialization.jsonObject(with: data, options: []) as AnyObject
                    {
                        do {
                            errorInfo = try errorParser(errorJson)
                        } catch {
                            print("Can't parse error JSON")
                            // We don't bother handling error on error message parsing
                        }
                    }
                    switch statusCode {
                    case 401:
                        completion(.error(NetworkingError.unauthorized))
                    case 400, 404, 422:
                        completion(.error(NetworkingError.invalidRequest(localizedDescription: errorInfo?.localizedDescription)))
                    case 500:
                        completion(.error(NetworkingError.serverError(localizedFailureReason: errorInfo?.localizedFailureReason)))
                    default:
                        print("WARNING : status code \(statusCode) not handled")
                        completion(.error(NetworkingError.unknown(localizedFailureReason: "status code \(statusCode) not handled")))
                    }
                } else {
                    completion(.error(NetworkingError.networkError(error: error)))
                }
            case .success(let json):
                do {
                    if self.debug {
                        print("json : \(json))")
                    }
                    let result = try resource.parseJSON(json as AnyObject)
                    completion(.success(result as A))
                } catch let error as NetworkingError {
                    completion(.error(error))
                } catch {
                    completion(.error(NetworkingError.unknown(localizedFailureReason: nil)))
                }
            }
        }
    }
}
