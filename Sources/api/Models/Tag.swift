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

final class Tag: BaseModel {
    
    let storage = Storage()
    
    static var permitted: [String] = ["name"]
    
    let name: String
    
    init(node: Node) throws {
        name = try node.extract("name")

        createdAt = try? node.extract(Tag.createdAtKey)
        updatedAt = try? node.extract(Tag.updatedAtKey)
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : name
        ]).add(objects: [
            "id" : id,
            Tag.createdAtKey : createdAt,
            Tag.updatedAtKey : updatedAt
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
