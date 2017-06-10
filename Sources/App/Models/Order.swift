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

fileprivate let separator = "@@@<<<>>>@@@"

final class Subscription: Model, Preparation, NodeConvertible, Sanitizable {
    
    var storage = Storage()
    
    static var permitted: [String] = ["product_id", "offer_id", "order_id", "fulfilled", "variants", "oneTime"]
    
    let product_id: Identifier
    let offer_id: Identifier?
    let maker_id: Identifier
    let order_id: Identifier
    
    let fulfilled: Bool
    var subscribed: Bool
    let oneTime: Bool
    let variants: [String: String]?
    
    var subcriptionIdentifier: String?
    
    init(node: Node) throws {
        if let parent = node.context as? ParentContext {
            order_id = parent.parent_id
        } else {
            order_id = try node.extract("order_id")
        }
        
        product_id = try node.extract("product_id")
        offer_id = try? node.extract("offer_id")
        
        guard let product = try Product.find(product_id) else {
            throw NodeError.unableToConvert(input: product_id.makeNode(in: emptyContext), expectation: "product_id pointing to correct product", path: ["product_id"])
        }
        
        maker_id = product.maker_id
        
        subcriptionIdentifier = try? node.extract("subcriptionIdentifier")
        subscribed = (try? node.extract("subscribed")) ?? false
        fulfilled = (try? node.extract("fulfilled")) ?? false
        oneTime = (try? node.extract("oneTime")) ?? false
        variants = try node["variants"]?.object?.converted(in: emptyContext)

        id = try? node.extract("id")
    }
    
    convenience init(row: Row) throws {
        var node = row.converted(to: Node.self)
        
        if let bytes: String = try? row.extract("variants") {
            let parsed = try JSON(bytes: bytes.makeBytes())
            node["variants"] = parsed.converted(to: Node.self)
        }
        
        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "maker_id" : maker_id,
            "order_id" : order_id,
            "product_id" : product_id,
            "oneTime" : oneTime,
            "fulfilled" : fulfilled,
            "subscribed" : subscribed,
        ]).add(objects: [
            "id" : id,
            "subcriptionIdentifier" : subcriptionIdentifier,
            "variants" : variants,
            "offer_id" : offer_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Subscription.self) { sub in
            sub.id()
            sub.parent(Product.self)
            sub.parent(Maker.self)
            sub.parent(Order.self)
            sub.parent(Offer.self, optional: true)
            sub.string("variants", optional: true)
            sub.bool("fulfilled", default: false)
            sub.bool("subscribed")
            sub.string("subcriptionIdentifier", optional: true)
            sub.bool("oneTime")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Subscription.self)
    }
}

extension Subscription {
    
    func maker() -> Parent<Subscription, Maker> {
        return parent(id: maker_id)
    }
    
    func product() -> Parent<Subscription, Product> {
        return parent(id: product_id)
    }
    
    func offer() -> Parent<Subscription, Offer> {
        return parent(id: offer_id)
    }
}

final class Order: Model, Preparation, NodeConvertible, Sanitizable {
    
    static func createOrder(for request: Request) throws -> Order {
        let node = try request.json().node
        
        let order: Order = try request.extractModel(injecting: request.customerInjectable())
        try order.save()
        
        guard let id = order.id else {
            throw Abort.custom(status: .internalServerError, message: "Failed to save order...")
        }
        
        var subscriptionNodes: [Node] = try node.extract("items")
            
        subscriptionNodes = try subscriptionNodes.map { (_node: Node) -> Node in
            var node = _node
            node.context = try ParentContext(id: id)
            return node
        }
        
        try subscriptionNodes.forEach {
            let item = try Subscription(node: $0)
            try item.save()
        }
        
        return order
    }

    var storage = Storage()
    
    static var permitted: [String] = ["customer_id", "customer_address_id", "card"]
    
    let customer_id: Identifier
    let customer_address_id: Identifier
    
    let card: String
    
    init(node: Node) throws {
        customer_id = try node.extract("customer_id")
        customer_address_id = try node.extract("customer_address_id")
    
        card = try node.extract("card")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "card" : card,
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            "customer_address_id" : customer_address_id
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
        return children(type: Subscription.self)
    }
}

