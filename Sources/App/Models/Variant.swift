//
//  Variant.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/7/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Variant: Model, Preparation, NodeConvertible, Sanitizable {
    
    let storage = Storage()
    
    static var permitted: [String] = ["name"]
    
    let name: String
    let options: [String]
    var product_id: Identifier
    
    init(node: Node) throws {
        name = try node.extract("name")
        product_id = try node.extract("product_id")
        
        let extracted: String = try node.extract("options")
        let parsed = try JSON(bytes: extracted.makeBytes())
        options = try parsed.converted(to: [String].self)
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : name,
            "options" : options,
            "product_id" : product_id
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Variant.self) { variant in
            variant.id()
            variant.string("name")
            variant.string("options")
            variant.parent(Product.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Variant.self)
    }
}

extension Variant {
    
    func product() -> Parent<Variant, Product> {
        return parent(id: product_id)
    }
}
