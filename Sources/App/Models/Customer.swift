//
//  File.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import BCrypt
import Node
import AuthProvider
import HTTP

extension Stripe {
    
    static func createStandaloneAccount(for customer: Customer, from source: Token, on account: String) throws -> StripeCustomer {
        guard let customerId = customer.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for customer.")
        }
        
        return try Stripe.createNormalAccount(email: customer.email, source: source.id, local_id: customerId, on: account)
    }
}

final class Customer: BaseModel, JWTInitializable, SessionPersistable {
    
    static var permitted: [String] = ["email", "name", "default_shipping_id"]
    
    let storage = Storage()
    
    let name: String
    let email: String
    
    var stripe_id: String?
    var sub_id: String?
    
    init(subject: String, request: Request) throws {
        sub_id = subject
        
        guard let providerData: Node = try request.json?.extract("providerData") else {
            throw Abort.custom(status: .badRequest, message: "Missing json body...")
        }
        
        self.name = try providerData.extract("displayName")
        self.email = try providerData.extract("email")
    }
    
    init(node: Node) throws {
        // Name and email are always mandatory
        email = try node.extract("email")
        name = try node.extract("name")
        stripe_id = try? node.extract("stripe_id")
        sub_id = try? node.extract("sub_id")

        createdAt = try? node.extract(Customer.createdAtKey)
        updatedAt = try? node.extract(Customer.updatedAtKey)
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        print("createdAt : \(createdAt?.description ?? ""). updatedAt: \(updatedAt?.description ?? "")")

        let test = try Node(node: [
            "name" : .string(name),
            "email" : .string(email)
        ]).add(objects: [
            "id" : id,
            "stripe_id" : stripe_id,
            "sub_id" : sub_id,
            Customer.createdAtKey : createdAt,
            Customer.updatedAtKey : updatedAt
        ])

        print("createdAt : \(test["createdAt"]?.string ?? ""). updatedAt: \(test["updatedAt"]?.string ?? "")")
        return test
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Customer.self) { customer in
            customer.id()
            customer.string("name")
            customer.string("stripe_id", optional: true)
            customer.string("email")
            customer.string("sub_id", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Customer.self)
    }
}

extension Customer {
    
    func shippingAddresses() -> Children<Customer, CustomerAddress> {
        return children()
    }
    
    func offers() -> Siblings<Customer, Offer, Pivot<Customer, Offer>> {
        return siblings()
    }

    func orders() -> Children<Customer, Order> {
        return children()
    }
}

extension Customer: Protected {

    func owners() throws -> [ModelOwner] {
        return try [ModelOwner(modelType: Customer.self, id: id())]
    }
}

extension Customer: Authenticatable {}

extension Customer {

    func stripeId() throws -> String {
        guard let id = self.stripe_id else {
            throw try Abort.custom(status: .badRequest, message: "Customer(\(self.id()) does not have a stripe id, call /stripe/customer/sources/{{latest_token}} to create one.")
        }

        return id
    }
}
