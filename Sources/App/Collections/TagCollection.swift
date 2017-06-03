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
