//
//  VariantController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/7/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

final class VariantController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Variant.all().makeResponse()
    }
    
    func show(_ request: Request, variant: Variant) throws -> ResponseRepresentable {
        return try variant.makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let variant: Variant = try request.extractModel()
        try variant.save()
        return try variant.makeResponse()
    }
    
    func delete(_ request: Request, variant: Variant) throws -> ResponseRepresentable {
        try variant.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, variant: Variant) throws -> ResponseRepresentable {
        let variant: Variant = try request.patchModel(variant)
        try variant.save()
        return try variant.makeResponse()
    }
    
    func makeResource() -> Resource<Variant> {
        return Resource(
            index: index,
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
