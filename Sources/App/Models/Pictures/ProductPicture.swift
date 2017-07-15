//
//  ProductPicture.swift
//  App
//
//  Created by Hakon Hanesand on 6/11/17.
//

import Vapor
import FluentProvider

final class ProductPicture: PictureBase {

    let storage = Storage()

    static var permitted: [String] = ["product_id", "url", "type"]

    let url: String
    let type: Int

    let product_id: Identifier
    let maker_id: Identifier

    static func pictures(for owner: Identifier) throws -> Query<ProductPicture> {
        return try self.makeQuery().filter("product_id", owner.int)
    }

    init(node: Node) throws {
        url = try node.extract("url")
        type = try node.extract("type")

        if let context = node.context as? ParentContext<Product> {
            product_id = context.parent_id
        } else {
            product_id = try node.extract("product_id")
        }

        if let maker_id: Identifier = try? node.extract("maker_id") {
            self.maker_id = maker_id
        } else {

            guard let maker = try Product.find(product_id)?.maker().first() else {
                throw Abort.custom(status: .badRequest, message: "Failed to get maker for linked product.")
            }

            self.maker_id = try maker.id()

            if let _: Identifier = try? node.get("id") {
                // We have been previously saved to the database, so save the
                // maker_id we just had to fetch to the row so its faster next time

                try self.save()
            }
        }

        createdAt = try? node.extract(ProductPicture.createdAtKey)
        updatedAt = try? node.extract(ProductPicture.updatedAtKey)

        id = try? node.extract("id")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url),
            "type" : .number(.int(type)),
            "product_id" : Identifier(product_id),
            "maker_id" : Identifier(maker_id)
        ]).add(objects: [
            "id" : id,
            ProductPicture.createdAtKey : createdAt,
            ProductPicture.updatedAtKey : updatedAt
        ])
    }

    class func prepare(_ database: Database) throws {
        try database.create(ProductPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.int("type")
            picture.parent(Product.self)
            picture.parent(Maker.self, unique: false)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(ProductPicture.self)
    }
}

extension ProductPicture: Protected {

    func owners() throws -> [ModelOwner] {
        return [ModelOwner(modelType: Maker.self, id: maker_id)]
    }
}

extension ProductPicture {

    func product() -> Parent<ProductPicture, Product> {
        return parent(id: product_id)
    }
}
