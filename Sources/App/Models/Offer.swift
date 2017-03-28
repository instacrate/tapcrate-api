//
//  Offer.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 3/19/17.
//
//

import Foundation
import Vapor
import Fluent
import Sanitized

enum OfferType: String, NodeConvertible {
    case free
    case coupon
    case deal
}

final class Offer: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["type", "product_id", "line_1", "line_2", "expiration", "code"]
    
    var id: Node?
    var exists = false
    
    let type: OfferType

    let line_1: String
    let line_2: String
    let expiration: Date
    let code: String

    var product_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        product_id = node["product_id"] ?? (context as? Node)
        type = try node.extract("type")
        line_1 = try node.extract("line_1")
        line_2 = try node.extract("line_2")
        expiration = try node.extract("expiration")
        code = try node.extract("code")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "type" : try type.makeNode(),
            "line_1" : .string(line_1),
            "line_2" : .string(line_2),
            "expiration" : try expiration.makeNode(),
            "code" : .string(code)
        ]).add(objects: [
            "id" : id,
            "product_id" : product_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { offer in
            offer.id()
            offer.string("type")
            offer.string("line_1")
            offer.string("line_2")
            offer.string("expiration")
            offer.string("code")
            offer.parent(Product.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Offer {
    
    func product() throws -> Parent<Product> {
        return try parent(product_id)
    }
}
