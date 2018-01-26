//
//  ViewController.swift
//  WebServices
//
//  Created by Ysix on 11/06/2017.
//  Copyright (c) 2017 Ysix. All rights reserved.
//

import UIKit
import WebService

struct Person {

    enum Gender: String {
        case male
        case female
    }

    var firstname: String
    var gender: Gender?

    static func gender(for firstname: String) -> WebResource<Person> {
        return WebResource<Person>(endPoint: URL(string: "https://api.genderize.io/")!, parameters: ["name" : firstname as AnyObject], parseJSON: { (JSON) -> (Person) in
            guard let personJSON = JSON as? JSONDictionary else {
                throw NetworkingError.dataCantBeParsed
            }
            return try Person.from(JSON: personJSON)
        })
    }

    static func from(JSON: JSONDictionary) throws -> Person {
        guard let firstname = JSON["name"] as? String else {
                throw NetworkingError.dataCantBeParsed
        }

        var gender: Gender? = nil
        if let rawGender = JSON["gender"] as? String {
            gender = Gender(rawValue: rawGender)
        }
        return Person(firstname: firstname, gender: gender)
    }
}

class ViewController: UIViewController, NetworkingErrorHandler {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        WebService.shared.defaultHeaders = ["Example Header": "This header will be in all requests if it's nor overwritten"]
        WebService.shared.debug = true

        WebService.shared.load(Person.gender(for: "Rick")) { (result) in
            switch result {
            case .error(let error):
                self.handleNetworkingError(error: error)
            case .success(let person):
                if let gender = person.gender {
                print("\(person.firstname) is probably a \(gender.rawValue)")
                } else {
                    print("Can't guess gender of " + person.firstname)
                }
            }
        }

        // in this request with set a wrong parameter (names instead of name)
        var badRequest = WebResource<Person>(endPoint: URL(string: "https://api.genderize.io/")!, parameters: ["names" : "Morty" as AnyObject], parseJSON: { (JSON) -> (Person) in
            guard let personJSON = JSON as? JSONDictionary else {
                throw NetworkingError.dataCantBeParsed
            }
            return try Person.from(JSON: personJSON)
        })
        badRequest.parseJSONError = { (JSON) -> ((NetworkingError.NetworkingErrorInfo?)) in
            guard let errorJSON = JSON as? JSONDictionary else {
                throw NetworkingError.dataCantBeParsed
            }
            return NetworkingError.NetworkingErrorInfo(localizedDescription: nil, localizedFailureReason: errorJSON["error"] as? String)
        }

        WebService.shared.load(badRequest) { (result) in
            switch result {
            case .error(let error):
                self.handleNetworkingError(error: error)
            case .success(let person):
                if let gender = person.gender {
                    print("\(person.firstname) is probably a \(gender.rawValue)")
                } else {
                    print("Can't guess gender of " + person.firstname)
                }
            }
        }
    }

    func handleUnauthorizedNetworkingError(completion: (() -> ())?) {
        // should not happen in this example
    }
}

