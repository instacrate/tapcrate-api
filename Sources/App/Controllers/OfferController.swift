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
        let offer: Offer = try request.extractModel(injecting: request.makerInjectable())

        guard let product = try offer.product().first() else {
            throw Abort.custom(status: .badRequest, message: "Linked product does not exist")
        }

        try Offer.ensure(action: .create, isAllowedOn: offer, by: request)
        try Product.ensure(action: .read, isAllowedOn: product, by: request)

        try offer.save()
        return try offer.makeResponse()
    }

    func delete(_ request: Request, offer: Offer) throws -> ResponseRepresentable {
        try Offer.ensure(action: .delete, isAllowedOn: offer, by: request)
        try offer.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, offer: Offer) throws -> ResponseRepresentable {
        try Offer.ensure(action: .delete, isAllowedOn: offer, by: request)

        let offer: Offer = try request.patchModel(offer)
        try offer.save()
        return try offer.makeResponse()
    }

    func makeResource() -> Resource<Offer> {
        return Resource(
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
