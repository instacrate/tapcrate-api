//
//  Offer.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 3/19/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

enum OfferType: String, NodeConvertible {
    case free
    case coupon
    case deal
}

final class Offer: Model, Preparation, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static let permitted = ["type", "product_id", "line_1", "line_2", "expiration", "code"]
    
    var id: Node?
    var exists = false
    
    let type: OfferType

    let line_1: String
    let line_2: String
    let expiration: Date
    let code: String

    var product_id: Identifier
    
    init(node: Node) throws {
        id = node["id"]
        
        type = try node.extract("type")
        line_1 = try node.extract("line_1")
        line_2 = try node.extract("line_2")
        expiration = try node.extract("expiration")
        code = try node.extract("code")
        
        if let context: ParentContext = node.context as? ParentContext {
            product_id = context.parent_id
        } else {
            product_id = try node.extract("product_id")
        }
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "type" : try type.makeNode(in: emptyContext),
            "line_1" : .string(line_1),
            "line_2" : .string(line_2),
            "expiration" : try expiration.makeNode(in: emptyContext),
            "code" : .string(code)
        ]).add(objects: [
            "id" : id,
            "product_id" : product_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Offer.self) { offer in
            offer.id()
            offer.string("type")
            offer.string("line_1")
            offer.string("line_2")
            offer.string("expiration")
            offer.string("code")
            offer.parent(Product.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Offer.self)
    }
}
