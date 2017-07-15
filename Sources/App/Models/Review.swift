//
//  Review.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Review: BaseModel {
    
    let storage = Storage()
    
    static var permitted: [String] = ["text", "rating", "product_id", "customer_id"]
    
    let text: String
    let rating: Int
    
    var product_id: Identifier
    var customer_id: Identifier
    
    init(node: Node) throws {
        text = try node.extract("text")
        rating = try node.extract("rating")
        
        product_id = try node.extract("product_id")
        customer_id = try node.extract("customer_id")

        createdAt = try? node.extract(Review.createdAtKey)
        updatedAt = try? node.extract(Review.updatedAtKey)
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "text" : .string(text),
            "rating" : .number(.int(rating)),
            "product_id" : product_id.makeNode(in: context),
            "customer_id" : customer_id.makeNode(in: context)
        ]).add(objects: [
            "id" : id,
            Review.createdAtKey : createdAt,
            Review.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Review.self, closure: { review in
            review.id()
            review.string("text")
            review.string("rating")
            review.parent(Product.self)
            review.parent(Customer.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Review.self)
    }
}

extension Review: Protected {

    func owners() throws -> [ModelOwner] {
        return [ModelOwner(modelType: Customer.self, id: customer_id)]
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
