//
//  Product.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider

final class Product: BaseModel {
    
    let storage = Storage()
    
    static var permitted: [String] = ["name", "fullPrice", "shortDescription", "longDescription", "maker_id"]
    
    let name: String
    let fullPrice: Double
    let shortDescription: String
    let longDescription: String
    
    let maker_id: Identifier
    
    init(node: Node) throws {
        name = try node.extract("name")
        fullPrice = try node.extract("fullPrice")
        shortDescription = try node.extract("shortDescription")
        longDescription = try node.extract("longDescription")
        maker_id = try node.extract("maker_id")

        createdAt = try? node.extract(Product.createdAtKey)
        updatedAt = try? node.extract(Product.updatedAtKey)

        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "fullPrice" : .number(.double(fullPrice)),
            "shortDescription" : .string(shortDescription),
            "longDescription" : .string(longDescription)
        ]).add(objects: [
            "id" : id,
            "maker_id" : maker_id,
            Product.createdAtKey : createdAt,
            Product.updatedAtKey : updatedAt
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Product.self) { product in
            product.id()
            product.string("name")
            product.double("fullPrice")
            product.string("shortDescription")
            product.string("longDescription")
            product.parent(Maker.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Product.self)
    }
}

extension Product {
    
    func maker() -> Parent<Product, Maker> {
        return parent(id: maker_id)
    }
    
    func tags() -> Siblings<Product, Tag, Pivot<Product, Tag>> {
        return siblings()
    }
    
    func pictures() -> Children<Product, ProductPicture> {
        return children()
    }
    
    func offers() -> Children<Product, Offer> {
        return children()
    }
    
    func plans() throws -> Query<ProductPlan> {
        return try children().filter("maker_id", maker_id)
    }
    
    func variants() -> Children<Product, Variant> {
        return children()
    }
    
    func reviews() -> Children<Product, Review> {
        return children()
    }

    static func expandableParents() -> [Relation]? {
        return [
            Relation(parent: Maker.self),
            Relation(child: ProductPicture.self, path: "pictures"),
            Relation(child: Offer.self),
            Relation(child: Tag.self),
            Relation(child: ProductPlan.self),
            Relation(child: Variant.self),
            Relation(child: Review.self)
        ]
    }
}

extension Product {
    
    func subscriptionPlanIdentifier() throws -> String {
        if let plan = try self.plans().first() {
            return plan.plan_id
        } else {
            guard let maker = try maker().first() else {
                throw Abort.custom(status: .internalServerError, message: "Could not get maker from product")
            }
            
            guard let secret = maker.keys?.secret else {
                throw try Abort.custom(status: .internalServerError, message: "Missing secret keys for vendor. \(maker.throwableId())")
            }
            
            let plan = try Stripe.createPlan(with: fullPrice, name: name, interval: .month, on: secret)
            let boxPlan = try ProductPlan(product: self, maker: maker, plan_id: plan.id)
            try boxPlan.save()
            
            return boxPlan.plan_id
        }
    }
}

extension Product: Protected {

    func owners() throws -> [ModelOwner] {
        return [ModelOwner(modelType: Maker.self, id: maker_id)]
    }

    var actionsAllowedForPublic: [ActionType] {
        return [.create, .read]
    }
}
