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
    case none
    case discount
    case free
    case percent
    case deal
}

final class Offer: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["type"]
    
    var id: Node?
    var exists = false
    
    let type: OfferType
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        type = try node.extract("type")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "type" : type
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { answer in
            answer.id()
            answer.string("type")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Tag {
    
    func products() throws -> Siblings<Product> {
        return try siblings()
    }
}
