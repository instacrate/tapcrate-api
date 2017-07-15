//
//  Subscription.swift
//  App
//
//  Created by Hakon Hanesand on 6/10/17.
//

import Vapor
import Fluent
import FluentProvider
import Node
import Foundation

import FluentProvider

final class Subscription: BaseModel {
    
    var storage = Storage()
    
    static var permitted: [String] = ["product_id", "offer_id", "order_id", "fulfilled", "variants", "oneTime"]
    
    let product_id: Identifier
    let offer_id: Identifier?
    let maker_id: Identifier
    let customer_id: Identifier
    let order_id: Identifier
    
    let fulfilled: Bool
    var subscribed: Bool
    let oneTime: Bool
    let variants: [String: String]?
    
    var subcriptionIdentifier: String?
    
    init(node: Node) throws {
        if let parent = node.context as? SecondaryParentContext<Order, Customer> {
            order_id = parent.parent_id
            customer_id = parent.secondary_id
        } else {
            order_id = try node.extract("order_id")
            customer_id = try node.extract("customer_id")
        }
        
        product_id = try node.extract("product_id")
        offer_id = try? node.extract("offer_id")

        if let maker_id: Identifier = try? node.extract("maker_id") {
            self.maker_id = maker_id
        } else {
            guard let product = try Product.find(product_id) else {
                throw NodeError.unableToConvert(input: product_id.makeNode(in: emptyContext), expectation: "product_id pointing to correct product", path: ["product_id"])
            }

            maker_id = product.maker_id
        }

        subcriptionIdentifier = try? node.extract("subcriptionIdentifier")
        subscribed = (try? node.extract("subscribed")) ?? false
        fulfilled = (try? node.extract("fulfilled")) ?? false
        oneTime = (try? node.extract("oneTime")) ?? false
        variants = try node["variants"]?.object?.converted(in: emptyContext)

        createdAt = try? node.extract(Subscription.createdAtKey)
        updatedAt = try? node.extract(Subscription.updatedAtKey)
        
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
            "customer_id" : customer_id,
            "oneTime" : oneTime,
            "fulfilled" : fulfilled,
            "subscribed" : subscribed,
        ]).add(objects: [
            "id" : id,
            "subcriptionIdentifier" : subcriptionIdentifier,
            "variants" : variants,
            "offer_id" : offer_id,
            Subscription.createdAtKey : createdAt,
            Subscription.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Subscription.self) { sub in
            sub.id()
            sub.parent(Product.self)
            sub.parent(Maker.self)
            sub.parent(Order.self)
            sub.parent(Customer.self)
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

extension Subscription: Protected {

    func owners() throws -> [ModelOwner] {
        return [
            ModelOwner(modelType: Maker.self, id: maker_id),
            ModelOwner(modelType: Customer.self, id: customer_id)
        ]
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
