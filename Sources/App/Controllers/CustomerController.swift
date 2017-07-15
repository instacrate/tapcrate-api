//
//  UserController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Vapor
import HTTP
import AuthProvider

enum FetchType: String, TypesafeOptionsParameter {
    
    case stripe
    case shipping
    
    static let key = "type"
    static let values = [FetchType.stripe.rawValue, FetchType.shipping.rawValue]
    
    static var defaultValue: FetchType? = nil
}

final class CustomerController {
    
    func detail(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()

        try Customer.ensure(action: .read, isAllowedOn: customer, by: request)
        
        if let expander: Expander<Customer> = try request.extract() {
            return try expander.expand(for: customer, mappings: { (relation, identifier: Identifier) -> [NodeRepresentable] in
                switch relation.path {
                case "cards":
                    return try Stripe.paymentInformation(for: customer.stripeId())
                    
                case "shipping":
                    return try customer.shippingAddresses().all()
                    
                default:
                    throw Abort.custom(status: .badRequest, message: "Could not find expansion for \(relation.path) on \(type(of: self)).")
                }
            }).makeResponse()
        }
        
        return try customer.makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let customer: Customer = try request.extractModel()

        try Customer.ensure(action: .create, isAllowedOn: customer, by: request)
        
        if try Customer.makeQuery().filter("email", customer.email).count() > 0 {
            throw Abort.custom(status: .badRequest, message: "Username is taken.")
        }
        
        try customer.save()
        request.multipleUserAuth.authenticate(customer)
        
        return try customer.makeResponse()
    }
    
    func modify(_ request: Request, customer: Customer) throws -> ResponseRepresentable {
        try Customer.ensure(action: .write, isAllowedOn: customer, by: request)
        
        let customer: Customer = try request.patchModel(customer)
        try customer.save()
        return try customer.makeResponse()
    }
}

extension CustomerController: ResourceRepresentable {
    
    func makeResource() -> Resource<Customer> {
        return Resource(
            index: detail,
            store: create,
            update: modify
        )
    }
}
