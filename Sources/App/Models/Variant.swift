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

final class Variant: BaseModel {
    
    let storage = Storage()
    
    static var permitted: [String] = ["name", "product_id", "options", "maker_id"]
    
    let name: String
    let options: [String]

    let product_id: Identifier
    let maker_id: Identifier
    
    init(node: Node) throws {
        name = try node.extract("name")
        options = try node.extract("options")
        
        if let parent = node.context as? SecondaryParentContext<Product, Maker> {
            product_id = parent.parent_id
            maker_id = parent.secondary_id
        } else {
            product_id = try node.extract("product_id")

            if let maker_id: Identifier = try? node.extract("maker_id") {
                self.maker_id = maker_id
            } else {
                guard let maker_id = try Product.find(product_id)?.maker_id else {
                    throw Abort.custom(status: .badRequest, message: "Could not find product linked from variant.")
                }

                self.maker_id = maker_id
            }
        }

        id = try? node.extract("id")
    }
    
    convenience init(row: Row) throws {
        var node: Node = row.converted()
        
        let extracted: String = try node.extract("options")
        let parsed = try JSON(bytes: extracted.makeBytes())
        try node.set("options", parsed.converted(to: [String].self))

        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : name,
            "options" : options,
            "product_id" : product_id,
            "maker_id" : maker_id
        ]).add(objects: [
            "id" : id,
            Variant.createdAtKey : createdAt,
            Variant.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Variant.self) { variant in
            variant.id()
            variant.string("name")
            variant.string("options")
            variant.parent(Maker.self)
            variant.parent(Product.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Variant.self)
    }
}

extension Variant: Protected  {

    func owner() throws -> ModelOwner {
        return .maker(id: maker_id)
    }
}

extension Variant {
    
    func product() -> Parent<Variant, Product> {
        return parent(id: product_id)
    }
}
