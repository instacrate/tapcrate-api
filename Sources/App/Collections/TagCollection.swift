//
//  TagCollection.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 6/3/17.
//
//

import HTTP
import Vapor
import Fluent

final class TagCollection: EmptyInitializable {
    
    required init() { }
    
    typealias Wrapped = HTTP.Responder
    
    func build(_ builder: RouteBuilder) {
        
        builder.group("products") { products in
            
            products.post(Product.parameter, "tags") { request in
                let product: Product = try request.parameters.next()
                let delete = request.query?["delete"]?.bool ?? false
                let rawTags = request.json
                
                if (delete) {
                    try product.tags().all().forEach {
                        try product.tags().remove($0)
                    }
                    
                }
                
                let tags: [Tag]
                
                if let _tagIds: [Int]? = try? rawTags?.array?.converted(in: emptyContext), let tagIds = _tagIds {
                    let ids = try tagIds.converted(to: Array<Node>.self, in: jsonContext)
                    tags = try Tag.makeQuery().filter(.subset(Tag.idKey, .in, ids)).all()
                } else if let _tags: [Node] = rawTags?.node.array {
                    tags = try _tags.map {
                        let tag = try Tag(node: $0)
                        try tag.save()
                        return tag
                    }
                } else {
                    throw Abort.custom(status: .badRequest, message: "Invalid json, must be array of new tags to create, or array of existing tag_ids")
                }
                
                try tags.forEach {
                    try product.tags().add($0)
                }
                
                return try product.tags().all().makeResponse()
            }
            
            products.post(Product.parameter, "tags", Tag.parameter) { request in
                let product: Product = try request.parameters.next()
                let tag: Tag = try request.parameters.next()
                
                guard try product.maker_id == request.maker().id() else {
                    throw Abort.custom(status: .unauthorized, message: "Can not modify another user's product.")
                }
                
                try Pivot<Tag, Product>.attach(tag, product)
                
                return try product.tags().all().makeResponse()
            }
            
            products.delete(Product.parameter, "tags", Tag.parameter) { request in
                let product: Product = try request.parameters.next()
                let tag: Tag = try request.parameters.next()
                
                guard try product.maker_id == request.maker().id() else {
                    throw Abort.custom(status: .unauthorized, message: "Can not modify another user's product.")
                }
                
                try Pivot<Tag, Product>.detach(tag, product)
                
                return try product.tags().all().makeResponse()
            }
        }
    }
}
