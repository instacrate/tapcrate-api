//
//  OfferController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 3/28/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

final class OfferController: ResourceRepresentable {

    func create(_ request: Request) throws -> ResponseRepresentable {
        var tag: Offer = try request.extractModel()
        try tag.save()
        return tag
    }

    func delete(_ request: Request, tag: Offer) throws -> ResponseRepresentable {
        try tag.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, tag: Offer) throws -> ResponseRepresentable {
        var tag: Offer = try request.patchModel(tag)
        try tag.save()
        return try Response(status: .ok, json: tag.makeJSON())
    }

    func makeResource() -> Resource<Offer> {
        return Resource(
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
