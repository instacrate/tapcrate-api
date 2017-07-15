//
//  ProductController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import HTTP
import Fluent
import FluentProvider
import Paginator

final class ProductController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        
        let sort = try request.extract() as Sort
        var query: Query<Product> = try Product.makeQuery()
        
        if let maker = request.query?["maker"]?.bool, maker {
            let maker = try request.maker()
            query = try maker.products().makeQuery()
        }

        let sortedQuery = try sort.modify(query)

        let paginator: Paginator<Product> = try sortedQuery.paginator(15, request: request) { models in
            if models.count == 0 {
                return Node.array([])
            }

            if let expander: Expander<Product> = try request.extract() {
                return try expander.expand(for: models) { (relation, identifiers: [Identifier]) in
                    switch relation.path {
                    case "tags":
                        return try collect(identifiers: identifiers, base: Product.self, relation: relation) as [[Tag]]

                    case "makers":
                        let makerIds = models.map { $0.maker_id }
                        return try collect(identifiers: makerIds, base: Product.self, relation: relation) as [[Maker]]

                    case "product_pictures":
                        return try collect(identifiers: identifiers, base: Product.self, relation: relation) as [[ProductPicture]]

                    case "offers":
                        return try collect(identifiers: identifiers, base: Product.self, relation: relation) as [[Offer]]

                    case "variants":
                        return try collect(identifiers: identifiers, base: Product.self, relation: relation) as [[Variant]]

                    case "reviews":
                        return try collect(identifiers: identifiers, base: Product.self, relation: relation) as [[Review]]

                    default:
                        throw Abort.custom(status: .badRequest, message: "Could not find expansion for \(relation.path) on \(type(of: self)).")
                    }
                }
            }

            return try models.makeNode(in: jsonContext)
        }

        return try paginator.makeResponse()
    }
    
    func show(_ request: Request, product: Product) throws -> ResponseRepresentable {

        try Product.ensure(action: .read, isAllowedOn: product, by: request)
        
        if let expander: Expander<Product> = try request.extract() {
            return try expander.expand(for: product, mappings: { (relation, identifier: Identifier) -> [NodeRepresentable] in
                switch relation.path {
                case "tags":
                    return try product.tags().all()
                case "maker":
                    return try product.maker().limit(1).all()
                case "product_pictures":
                    return try product.pictures().all()
                case "offers":
                    return try product.offers().all()
                case "variants":
                    return try product.variants().all()
                case "reviews":
                    return try product.reviews().all()
                default:
                    throw Abort.custom(status: .badRequest, message: "Could not find expansion for \(relation.path) on \(type(of: self)).")
                }
            }).makeResponse()
        }
        
        return try product.makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var result: [String : Node] = [:]
        
        let product: Product = try request.extractModel(injecting: request.makerInjectable())
        try Product.ensure(action: .read, isAllowedOn: product, by: request)
        try product.save()
        
        guard let product_id = product.id else {
            throw Abort.custom(status: .internalServerError, message: "Failed to save product.")
        }
        
        result["product"] = try product.makeNode(in: emptyContext)
        
        guard let node = request.json?.node else {
            return try JSON(result.makeNode(in: jsonContext))
        }
        
        if let pictureNode: [Node] = try? node.extract("pictures") {
            
            let context = try ParentContext<Product>(product_id)
            
            let pictures = try pictureNode.map { (object: Node) -> ProductPicture in
                let picture: ProductPicture = try ProductPicture(node: Node(object.permit(ProductPicture.permitted).wrapped, in: context))
                try picture.save()
                return picture
            }
            
            result["pictures"] = try pictures.makeNode(in: jsonContext)
        }
        
        if let tags: [Int] = try? node.extract("tags") {
            
            let tags = try tags.map { (id: Int) -> Tag? in
                guard let tag = try Tag.find(id) else {
                    return nil
                }
                
                let pivot = try Pivot<Tag, Product>(tag, product)
                try pivot.save()
                
                return tag
            }.flatMap { $0 }
            
            result["tags"] = try tags.makeNode(in: emptyContext)
        }
        
        if let variantNodes: [Node] = try? node.extract("variants") {
            
            let context = try SecondaryParentContext<Product, Maker>(product.id, product.maker_id)
            
            let variants = try variantNodes.map { (variantNode: Node) -> Variant in
                let variant = try Variant(node: Node(variantNode.permit(Variant.permitted).wrapped, in: context))
                try variant.save()
                return variant
            }
            
            result["variants"] = try variants.makeNode(in: jsonContext)
        }
        
        return try JSON(result.makeNode(in: jsonContext))
    }
    
    func delete(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try Product.ensure(action: .delete, isAllowedOn: product, by: request)
        try product.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try Product.ensure(action: .write, isAllowedOn: product, by: request)
        
        let product: Product = try request.patchModel(product)
        try product.save()
        
        return try product.makeResponse()
    }
    
    func makeResource() -> Resource<Product> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: modify,
            destroy: delete
        )
    }
}
