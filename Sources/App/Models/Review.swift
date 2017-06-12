//
//  Review.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Review: Model, Preparation, NodeConvertible, Sanitizable {
    
    let storage = Storage()
    
    static var permitted: [String] = ["text", "rating", "product_id", "customer_id", "date"]
    
    let text: String
    let rating: Int
    let date: Date
    
    var product_id: Identifier
    var customer_id: Identifier
    
    init(node: Node) throws {
        text = try node.extract("text")
        rating = try node.extract("rating")
        
        product_id = try node.extract("product_id")
        customer_id = try node.extract("customer_id")

        date = (try? node.extract("date")) ?? Date()
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "text" : .string(text),
            "rating" : .number(.int(rating)),
            "date" : date.makeNode(in: context),
            "product_id" : product_id.makeNode(in: context),
            "customer_id" : customer_id.makeNode(in: context)
        ]).add(name: "id", node: id.makeNode(in: context))
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Review.self, closure: { review in
            review.id()
            review.string("text")
            review.string("rating")
            review.string("date")
            review.parent(Product.self)
            review.parent(Customer.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Review.self)
    }
}

extension Review: Protected {

    func owner() throws -> ModelOwner {
        return .customer(id: customer_id)
    }
}

extension Review {
    
    func product() -> Parent<Review, Product> {
        return parent(id: product_id)
    }
    
    func customer() -> Parent<Review, Customer> {
        return parent(id: customer_id)
    }
}
