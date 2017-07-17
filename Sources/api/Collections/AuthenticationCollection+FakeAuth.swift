//
//  AuthenticationCollection+FakeAuth.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import JWT
import Authentication
import HTTP
import Vapor

extension AuthenticationCollection {
    
    func performFakeLogin(with token: JWT, for subject: String, from request: Request) throws -> Response {
        guard let authenticationId = subject.int else {
            throw AuthenticationError.notAuthenticated
        }
        
        let type: SessionType = try request.extract()
        
        switch type {
        case .customer:
            guard let customer = try Customer.find(authenticationId) else {
                throw AuthenticationError.notAuthenticated
            }
            
            request.multipleUserAuth.authenticate(customer)
            return try customer.makeResponse()
            
        case .maker:
            guard let maker = try Maker.find(authenticationId) else {
                throw AuthenticationError.notAuthenticated
            }
            
            request.multipleUserAuth.authenticate(maker)
            return try maker.makeResponse()
        }
    }
}
