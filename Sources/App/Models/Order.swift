//
//  Order.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

extension Order {
    
    static func createOrder(for request: Request) throws -> Order {
        let node = try request.json().node
        let subscriptionNodes: [Node] = try node.extract("items")
        
        guard subscriptionNodes.count > 0 else {
            throw Abort.custom(status: .badRequest, message: "Can not create order with no subscriptions.")
        }
        
        let order: Order = try request.extractModel(injecting: request.customerInjectable())
        try Order.ensure(action: .create, isAllowedOn: order, by: request)
        try order.save()

        let context = try SecondaryParentContext<Order, Customer>(order.id, order.customer_id)

        try subscriptionNodes.forEach {
            let subscription = try Subscription(sanitizing: $0, in: context)
            try subscription.save()
        }

        return order
    }
}

final class Order: BaseModel {

    var storage = Storage()
    
    static var permitted: [String] = ["customer_id", "customer_address_id", "card"]
    
    let card: String
    let customer_id: Identifier
    let customer_address_id: Identifier
    
    init(node: Node) throws {
        customer_id = try node.extract("customer_id")
        customer_address_id = try node.extract("customer_address_id")
    
        card = try node.extract("card")
        createdAt = try? node.extract(Order.createdAtKey)
        updatedAt = try? node.extract(Order.updatedAtKey)

        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "card" : card,
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            "customer_address_id" : customer_address_id,
            Offer.createdAtKey : createdAt,
            Offer.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Order.self) { order in
            order.id()
            order.string("card")
            order.parent(Customer.self)
            order.parent(CustomerAddress.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Order.self)
    }
}

extension Order {
    
    func customer() -> Parent<Order, Customer> {
        return parent(id: customer_id)
    }
    
    func address() -> Parent<Order, CustomerAddress> {
        return parent(id: customer_address_id)
    }
    
    func items() -> Children<Order, Subscription> {
        return children()
    }

    static func expandableParents() -> [Relation]? {
        return [
            Relation(parent: CustomerAddress.self)
        ]
    }
}

extension Order: Protected {

    func owners() throws -> [ModelOwner] {
        var owners = try self.items().all().map { ModelOwner(modelType: Maker.self, id: $0.maker_id) }
        owners.append(ModelOwner(modelType: Customer.self, id: customer_id))
        return owners
    }
}

