//
//  Subscription.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 7/15/17.
//

import Foundation

import HTTP
import Vapor
import Fluent

final class SubscriptionController: ResourceRepresentable {

    func modify(_ request: Request, old: Subscription) throws -> ResponseRepresentable {
        let new: Subscription = try request.patchModel(old)
        try Review.ensure(action: .write, isAllowedOn: new, by: request)
        try new.save()

        if old.subscribed && !new.subscribed {
            // stop subscription
        }

        return try new.makeResponse()
    }

    func makeResource() -> Resource<Subscription> {
        return Resource(
            update: modify
        )
    }
}
