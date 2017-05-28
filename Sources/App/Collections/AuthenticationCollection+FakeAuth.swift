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
        guard let newSubject = subject.replacingOccurrences(of: "__testing__", with: "").int else {
            throw AuthenticationError.notAuthenticated
        }
        
        let type: SessionType = try request.extract()
        
        switch type {
        case .customer:
            guard let customer = try Customer.find(newSubject) else {
                throw AuthenticationError.notAuthenticated
            }
            
            request.multipleUserAuth.authenticate(customer)
            return try customer.makeResponse()
            
        case .maker:
            guard let maker = try Maker.find(newSubject) else {
                throw AuthenticationError.notAuthenticated
            }
            
            request.multipleUserAuth.authenticate(maker)
            return try maker.makeResponse()
            
        case .anonymous:
            throw Abort.custom(status: .badRequest, message: "Can not sign user up with anonymous session type.")
        }
    }
}
