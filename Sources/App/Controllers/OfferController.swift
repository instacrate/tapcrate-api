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
        let offer: Offer = try request.extractModel()
        try offer.save()
        return try offer.makeJSON().makeResponse()
    }

    func delete(_ request: Request, offer: Offer) throws -> ResponseRepresentable {
        try offer.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, offer: Offer) throws -> ResponseRepresentable {
        let offer: Offer = try request.patchModel(offer)
        try offer.save()
        return try Response(status: .ok, json: offer.makeJSON())
    }

    func makeResource() -> Resource<Offer> {
        return Resource(
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
