//
//  ProductPlan.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/9/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class ProductPlan: Model, Preparation, NodeConvertible {
    
    let storage = Storage()
    
    let product_id: Identifier
    let maker_id: Identifier
    
    let plan_id: String
    
    init(product: Product, maker: Maker) throws {
        maker_id = maker.id!
        product_id = product.id!
        plan_id = UUID().uuidString
    }
    
    init(node: Node) throws {
        plan_id = try node.extract("plan_id")
        product_id = try node.extract("product_id")
        maker_id = try node.extract("maker_id")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "plan_id" : plan_id,
            "maker_id" : maker_id
        ]).add(objects: [
            "id" : id,
            "product_id" : product_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(ProductPlan.self) { plan in
            plan.id()
            plan.parent(Product.self)
            plan.parent(Maker.self)
            plan.string("plan_id")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(ProductPlan.self)
    }
}
