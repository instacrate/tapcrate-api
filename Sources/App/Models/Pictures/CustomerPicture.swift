//
//  CustomerPicture.swift
//  App
//
//  Created by Hakon Hanesand on 6/11/17.
//

import Vapor
import FluentProvider

final class CustomerPicture: PictureBase {

    let storage = Storage()

    static var permitted: [String] = ["customer_id", "url"]

    let customer_id: Identifier
    let url: String

    static func pictures(for owner: Identifier) throws -> Query<CustomerPicture> {
        return try self.makeQuery().filter("customer_id", owner.int)
    }

    init(node: Node) throws {
        url = try node.extract("url")

        if let context = node.context as? ParentContext<Customer> {
            customer_id = context.parent_id
        } else {
            customer_id = try node.extract("customer_id")
        }

        createdAt = try? node.extract(CustomerPicture.createdAtKey)
        updatedAt = try? node.extract(CustomerPicture.updatedAtKey)

        id = try? node.extract("id")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id,
            CustomerPicture.createdAtKey : createdAt,
            CustomerPicture.updatedAtKey : updatedAt
        ])
    }

    class func prepare(_ database: Database) throws {
        try database.create(CustomerPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.parent(Customer.self)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(CustomerPicture.self)
    }
}

extension CustomerPicture: Protected {

    func owners() throws -> [ModelOwner] {
        return [ModelOwner(modelType: Customer.self, id: customer_id)]
    }
}
