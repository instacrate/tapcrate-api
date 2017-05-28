//
//  ReviewController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

extension Review {
    
    func shouldAllow(request: Request) throws {
        guard let customer = try? request.customer() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Review(\(throwableId())) by this user. Must be logged in as Customer(\(customer_id.int ?? 0)).")
        }
        
        guard try customer.throwableId() == customer_id.int else {
            throw try Abort.custom(status: .forbidden, message: "This Customer(\(customer.throwableId())) does not have access to resource Review(\(throwableId()). Must be logged in as Customer(\(customer_id.int ?? 0).")
        }
    }
}

final class ReviewController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let review: Review = try request.extractModel(injecting: request.customerInjectable())
        try review.save()
        
        return try review.makeResponse()
    }
    
    func modify(_ request: Request, review: Review) throws -> ResponseRepresentable {
        try review.shouldAllow(request: request)
        
        let review: Review = try request.patchModel(review)
        try review.save()
        
        return try review.makeResponse()
    }
    
    func delete(_ request: Request, review: Review) throws -> ResponseRepresentable {
        try review.delete()
        return Response(status: .noContent)
    }
    
    func makeResource() -> Resource<Review> {
        return Resource(
            store: create,
            update: modify
        )
    }
}
