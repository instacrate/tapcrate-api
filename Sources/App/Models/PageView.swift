//
//  PageView.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 4/28/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class PageView: BaseModel {
    
    let storage = Storage()
    
    static var permitted: [String] = ["ip", "product_id", "customer_id"]
    
    let ip: String
    let product_id: Identifier
    let customer_id: Identifier?
    
    init(node: Node) throws {
        ip = try node.extract("ip")
        
        customer_id = try? node.extract("customer_id")
        product_id = try node.extract("product_id")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "ip" : ip,
            "product_id" : product_id
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            PageView.createdAtKey : createdAt,
            PageView.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(PageView.self) { pageView in
            pageView.id()
            pageView.string("ip")
            pageView.parent(Product.self)
            pageView.parent(Customer.self, optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(PageView.self)
    }
}
