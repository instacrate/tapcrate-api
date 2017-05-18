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

final class OrderItem: Model, Preparation, NodeConvertible, Sanitizable {
    
    var storage = Storage()
    
    static var permitted: [String] = ["product_id", "offer_id", "variants", "subscribe"]
    
    let product_id: Identifier
    let maker_id: Identifier
    let offer_id: Identifier
    let order_id: Identifier
    
    let fulfilled: Bool
    let subscribe: Bool
    let variants: [Int: String]
    
    init(node: Node) throws {
        product_id = try node.extract("product_id")
        offer_id = try node.extract("offer_id")
        order_id = try node.extract("order_id")
        subscribe = try node.extract("subscribe")
        
        guard let product = try Product.find(product_id) else {
            throw NodeError.unableToConvert(input: product_id.makeNode(in: emptyContext), expectation: "product_id pointing to correct product", path: ["product_id"])
        }
        
        maker_id = product.maker_id
        
        let extracted: String = try node.extract("variants")
        let parsed = try JSON(bytes: extracted.makeBytes())
        variants = try parsed.converted(to: [Int : String].self)
        
        fulfilled = (try? node.extract("fulfilled")) ?? false
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "maker_id" : maker_id,
            "product_id" : product_id,
            "offer_id" : offer_id,
            "variants" : variants,
            "fulfilled" : fulfilled,
            "subscribe" : subscribe
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(OrderItem.self) { orderItem in
            orderItem.parent(Product.self)
            orderItem.parent(Maker.self)
            orderItem.bool("fulfilled", default: false)
            orderItem.bool("subscribe")
            orderItem.string("variants")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(OrderItem.self)
    }
}

extension OrderItem {
    
    func maker() -> Parent<OrderItem, Maker> {
        return parent(id: maker_id)
    }
    
    func product() -> Parent<OrderItem, Product> {
        return parent(id: product_id)
    }
    
    func offer() -> Parent<OrderItem, Offer> {
        return parent(id: offer_id)
    }
}

final class Order: Model, Preparation, NodeConvertible, Sanitizable {
    
    static func createOrder(for request: Request) throws -> Order {
        guard let node = request.json?.node else {
            throw Abort.custom(status: .badRequest, message: "Missing JSON body.")
        }
        
        let order: Order = try request.extractModel(injecting: request.customerInjectable())
        try order.save()
        
        let nodeItems: [Node] = try node.extract("items")
        try nodeItems.forEach {
            var node = $0
            node["order_id"] = try order.id.makeNode(in: emptyContext)
            let item = try OrderItem(node: node)
            try item.save()
        }
        
        return order
    }

    var storage = Storage()
    
    static var permitted: [String] = ["customer_id", "customer_address_id", "card"]
    
    let customer_id: Identifier
    let customer_address_id: Identifier
    
    let card: String
    var charge_id: String?
    
    init(node: Node) throws {
        customer_id = try node.extract("customer_id")
        customer_address_id = try node.extract("customer_address_id")
    
        card = try node.extract("card")
        charge_id = try? node.extract("charge_id")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "card" : card,
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            "customer_address_id" : customer_address_id,
            "charge_id" : charge_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Order.self) { order in
            order.id()
            order.string("card")
            order.string("charge_id")
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
        return parent(id: customer_id)
    }
    
    func items() -> Children<Order, OrderItem> {
        return children(type: OrderItem.self)
    }
}

