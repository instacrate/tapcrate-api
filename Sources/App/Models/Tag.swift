//
//  Tag.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Tag: Model, Preparation, NodeConvertible, Sanitizable {
    
    let storage = Storage()
    
    static var permitted: [String] = ["name"]
    
    let name: String
    
    init(node: Node) throws {
        name = try node.extract("name")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : name
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Tag.self) { tag in
            tag.id()
            tag.string("name")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Tag.self)
    }
}

extension Tag {
    
    func products() -> Siblings<Tag, Product, Pivot<Tag, Product>> {
        return siblings()
    }
}
