//
//  VendorAddress.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class MakerAddress: Model, Preparation, NodeConvertible, Sanitizable {
    
    let storage = Storage()
    
    static var permitted: [String] = ["address", "apartment", "city", "state", "zip"]
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    
    var maker_id: Identifier
    
    init(node: Node) throws {
        address = try node.extract("address")
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
        
        if let parent = node.context as? ParentContext {
            maker_id = parent.parent_id
        } else {
            maker_id = try node.extract("maker_id")
        }
        
        apartment = try? node.extract("apartment")
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip),
            "maker_id" : maker_id
        ]).add(objects: [
            "id" : id,
            "apartment" : apartment
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(MakerAddress.self) { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment", optional: true)
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
            shipping.parent(Maker.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(MakerAddress.self)
    }
}
