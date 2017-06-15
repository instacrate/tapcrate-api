//
//  Email.swift
//  App
//
//  Created by Hakon Hanesand on 6/15/17.
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Email: BaseModel {

    let storage = Storage()

    static var permitted: [String] = ["email", "ip"]

    let email: String
    let ip: String
    let customer_id: Identifier?

    init(node: Node) throws {
        ip = try node.extract("ip")
        email = try node.extract("email")
        customer_id = try? node.extract("customer_id")

        id = try? node.extract("id")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "email" : email,
            "ip" : ip
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            Email.createdAtKey : createdAt,
            Email.updatedAtKey : updatedAt
        ])
    }

    static func prepare(_ database: Database) throws {
        try database.create(Email.self) { email in
            email.id()
            email.string("email")
            email.string("ip")
            email.parent(Customer.self, optional: true)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(Email.self)
    }
}

