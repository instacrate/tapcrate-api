//
//  AuthenticationCollection+Helpers.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import Vapor
import Authentication
import HTTP

extension AuthenticationCollection {
    
    static let googleKeySource = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
    
    func fetchSigningKey(for identifier: String) throws -> String {
        if let key = keys[identifier] {
            return key
        }
        
        let response = try drop.client.get(AuthenticationCollection.googleKeySource)
        
        guard let fetchedKeys = response.json?.object else {
            throw Abort.custom(status: .internalServerError, message: "Could not get new signing keys.")
        }
        
        var newKeyLookup: [String : String] = [:]
        
        try fetchedKeys.forEach { (arg: (key: String, value: JSON)) -> () in
            let (key, value) = arg

            guard let string = value.string else {
                throw NodeError.unableToConvert(input: value.node, expectation: "\(String.self)", path: [key])
            }
            
            newKeyLookup[key] = string
        }
        
        keys = newKeyLookup
        
        guard let key = newKeyLookup[identifier] else {
            throw Abort.custom(status: .internalServerError, message: "\(identifier) key does not exist.")
        }
        
        return key
    }
    
    func authenticateUserFor(subject: String, with request: Request) throws -> AuthenticationSubject {
        let type: SessionType = try request.extract()
        
        switch type {
        case .customer:
            let customer = try getAuthenticationSubject(subject: subject, request: request) as Customer
            request.multipleUserAuth.authenticate(customer)
            return customer
            
        case .maker:
            let maker = try getAuthenticationSubject(subject: subject, request: request) as Maker
            request.multipleUserAuth.authenticate(maker)
            return maker
            
        case .anonymous:
            throw Abort.custom(status: .badRequest, message: "Can not sign user up with anonymous session type.")
        }
    }
    
    func getAuthenticationSubject<T: AuthenticationSubject>(subject: String, request: Request) throws -> T {
        if let callee = try T.makeQuery().filter("sub_id", subject).first() {
            return callee
        }

        let subject = try T.init(subject: subject, request: request)
        try subject.save()
        return subject
    }
}
