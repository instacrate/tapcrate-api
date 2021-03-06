//
//  StripeMakerCustomer.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class StripeMakerCustomer: BaseInternalModel {
    
    let storage = Storage()
    
    let customer_id: Identifier
    let maker_id: Identifier
    
    let stripeCustomerId: String
    
    init(maker: Maker, customer: Customer, account: String) throws {
        guard let maker_id = maker.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing maker id for StripeMakerCustomer link.")
        }
        
        guard let customer_id = customer.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for StripeMakerCustomer link.")
        }
        
        self.customer_id = customer_id
        self.maker_id = maker_id
        self.stripeCustomerId = account
    }
    
    init(node: Node) throws {
        customer_id = try node.extract("customer_id")
        maker_id = try node.extract("maker_id")
        stripeCustomerId = try node.extract("stripeCustomerId")

        createdAt = try? node.extract(StripeMakerCustomer.createdAtKey)
        updatedAt = try? node.extract(StripeMakerCustomer.updatedAtKey)
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "stripeCustomerId" : stripeCustomerId,
            "customer_id" : customer_id.makeNode(in: context),
            "maker_id" : maker_id.makeNode(in: context)
        ]).add(objects: [
            "id" : id,
            StripeMakerCustomer.createdAtKey : createdAt,
            StripeMakerCustomer.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(StripeMakerCustomer.self) { stripeMakerCustomer in
            stripeMakerCustomer.id()
            stripeMakerCustomer.parent(Customer.self)
            stripeMakerCustomer.parent(Maker.self)
            stripeMakerCustomer.string("stripeCustomerId")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(StripeMakerCustomer.self)
    }
}

extension StripeMakerCustomer {
    
    func vendor() -> Parent<StripeMakerCustomer, Maker> {
        return parent(id: maker_id)
    }
    
    func customer() -> Parent<StripeMakerCustomer, Customer> {
        return parent(id: customer_id)
    }
}
