//
//  ReviewController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

final class ReviewController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let review: Review = try request.extractModel(injecting: request.customerInjectable())
        try Review.ensure(action: .create, isAllowedOn: review, by: request)
        try review.save()
        
        return try review.makeResponse()
    }
    
    func modify(_ request: Request, review: Review) throws -> ResponseRepresentable {
        let review: Review = try request.patchModel(review)
        try Review.ensure(action: .write, isAllowedOn: review, by: request)
        try review.save()
        
        return try review.makeResponse()
    }
    
    func delete(_ request: Request, review: Review) throws -> ResponseRepresentable {
        try Review.ensure(action: .delete, isAllowedOn: review, by: request)
        try review.delete()
        return Response(status: .noContent)
    }
    
    func makeResource() -> Resource<Review> {
        return Resource(
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
