//
//  NetworkingError.swift
//  WebServices
//
//  Created by Eddy Claessens on 07/11/2017.
//

import Foundation

public protocol NetworkingErrorHandler {
    func handleNetworkingError(error: NetworkingError, completion: (() -> ())?)
    func handleUnauthorizedNetworkingError(completion: (() -> ())?) // this is very specific (interact with session data (app logic) or specific on login for exemple) -> handler has to handle it (but you can make an other protocol to handle the "disconnect" keeping this part in your app logic)
}

public extension NetworkingErrorHandler where Self: UIViewController { // convenient handler not based on your app logic but on UX best practics
    
    func handleNetworkingError(error: NetworkingError, completion: (() -> ())? = nil) {
        print("error : \(error.localizedFailureReason)")
        switch error {
        case .notConnectedToInternet:
            // do nothing (an error message should be displayed in the UI to tell the user the problem).
            break;
        case .unauthorized:
            self.handleUnauthorizedNetworkingError(completion: completion)
        default:
            let message = error.localizedDescription
            let alert = UIAlertController(title: NSLocalizedString("Oops", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: ""), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: ""), style: .cancel, handler: { _ in
                if let completion = completion {
                    completion()
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

public enum NetworkingError: Error { //TODO: do a protocol for this, and an enum to handle default cases. (let app add more error types that can be thrown by the parseJSON method)
    
    public typealias NetworkingErrorInfo = (localizedDescription: String?, localizedFailureReason: String?)
    
    static let bundle = Bundle.main
    static let domain = bundle.bundleIdentifier! + ".Networking.Error"
    
    case unknown(localizedFailureReason: String?)
    case notConnectedToInternet
    case networkError(error: Error) // Capture any underlying Error from the URLSession API (other that no internet connection)
    case serverError(localizedFailureReason: String?)
    case invalidRequest(localizedDescription: String?)
    case unauthorized
    case dataCantBeParsed
    
    var code: Int {
        switch self {
        case .unknown:
            return 0
        case .networkError:
            return 1
        case .serverError:
            return 2
        case .invalidRequest:
            return 3
        case .unauthorized:
            return 4
        case .dataCantBeParsed:
            return 5
        case .notConnectedToInternet:
            return 6
        }
    }
    
    var localizedDescription: String { // for user display
        
        let defaultDescription = NSLocalizedString("An error occured", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        
        switch self {
        case .unknown, .serverError, .dataCantBeParsed:
            return defaultDescription
        case .networkError(let error):
            return error.localizedDescription
        case .unauthorized:
            return NSLocalizedString("Your session has expired", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        case .invalidRequest(let message):
            guard let message = message else {
                return defaultDescription
            }
            return message
        case .notConnectedToInternet:
            return NSLocalizedString("You are not connected to Internet", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        }
    }
    
    var localizedFailureReason: String { // for developer
        switch self {
        case .unknown(let info):
            return info ??  NSLocalizedString("Unknown error", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        case .networkError(let error):
            return  NSLocalizedString("Network error", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "") + error.localizedDescription
        case .serverError(let message):
            return  NSLocalizedString("Server error ", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "") + (message ?? "")
        case .invalidRequest(let message):
            return  NSLocalizedString("Invalid request ", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "") + (message ?? "")
        case .unauthorized:
            return "User session has expired"
        case .dataCantBeParsed:
            return  NSLocalizedString("Data are not in correct format and can't be parsed.", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        case .notConnectedToInternet:
            return NSLocalizedString("Not connected to Internet", tableName: "NetworkingError", bundle: NetworkingError.bundle, comment: "")
        }
    }
    
    var nsError: NSError {
        return NSError(domain: NetworkingError.domain, code: self.code, userInfo: [NSLocalizedDescriptionKey: self.localizedDescription, NSLocalizedFailureReasonErrorKey : self.localizedFailureReason])
    }
}
