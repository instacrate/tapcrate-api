//
//  MakerController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Vapor
import HTTP
import AuthProvider

final class MakerController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let maker = try request.maker()
        
        if let expander: Expander<Maker> = try request.extract() {
            return try expander.expand(for: maker, mappings: { (relation, models, ids) -> [NodeRepresentable] in
                switch relation {
                    case "pictures":
                        return try [maker.pictures().all()]
                    default:
                        throw Abort.custom(status: .badRequest, message: "Could not find expansion for \(relation) on \(type(of: self)).")
                }
            }).makeResponse()
        }
        
        return try maker.makeResponse()
    }
    
    func show(_ request: Request, maker: Maker) throws -> ResponseRepresentable {
        try Maker.ensure(action: .read, isAllowedOn: maker, by: request)

        return try maker.makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let maker = try Maker.createMaker(from: request)

        request.multipleUserAuth.authenticate(maker)
        
        let account = try Stripe.createManagedAccount(email: maker.contactEmail, local_id: maker.id?.int)
        
        maker.stripe_id = account.id
        maker.keys = account.keys
        try maker.save()
        
        return try maker.makeResponse()
    }
    
    func modify(_ request: Request, maker: Maker) throws -> ResponseRepresentable {
        try Maker.ensure(action: .write, isAllowedOn: maker, by: request)
        
        let maker: Maker = try request.patchModel(maker)
        try maker.save()
        
        return try maker.makeResponse()
    }
    
    func makeResource() -> Resource<Maker> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: modify
        )
    }
}

