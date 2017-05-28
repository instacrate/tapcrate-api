//
//  OrderController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider
import Dollar

extension Stripe {
    
    func charge(order: inout Order) throws {
        
        guard let customer = try order.customer().first() else {
            throw Abort.custom(status: .badRequest, message: "no customer")
        }

        return try order.items().all().forEach { (item: Subscription) in
            guard
                let product = try item.product().first(),
                let maker = try item.maker().first(),
                let secret = maker.keys?.secret
            else {
                throw Abort.custom(status: .internalServerError, message: "malformed order item object")
            }
            
            let plan = try product.subscriptionPlanIdentifier()
            let customer = try maker.connectAccount(for: customer, with: order.card)
            
            let stripeSubscription = try Stripe.shared.subscribe(user: customer, to: plan, oneTime: false, cut: maker.cut, metadata: [:], under: secret)
            
            item.subscribed = true
            item.subcriptionIdentifier = stripeSubscription.id
            try item.save()
        }
    }
}

extension Node {
    
    mutating func replace(relation at: String, with relation: Node) {
        self["\(at)_id"] = nil
        self[at] = relation
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let type: SessionType = try request.extract()

        switch type {
        case .customer:
            return try request.customer().orders().all().makeResponse()
        case .maker:
            var query = try request.maker().subscriptions().makeQuery()

            if let fulfilled = request.query?["fulfilled"]?.bool {
                query = try query.filter("fulfilled", fulfilled)
            }
            
            let subscriptions = try query.all()
            
            let groupedSubscriptions = $.groupBy(subscriptions) {
                return $0.id!.int!
            }
            
            let subIds = Array(groupedSubscriptions.keys).map { Node.number(.int($0)) }
            let orders = try Order.makeQuery().filter(.subset(Order.idKey, .in, subIds)).all()
            
            var result: [Node] = []
            
            for order in orders {
                var orderNode = try order.makeNode(in: jsonContext)
                orderNode["subscriptions"] = try groupedSubscriptions[order.id!.int!].makeNode(in: jsonContext)
                result.append(orderNode)
            }
            
            return try subscriptions.makeResponse()
        case .anonymous:
            return try Order.all().makeResponse()
        }
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var order = try Order.createOrder(for: request)
        try Stripe.shared.charge(order: &order)
        return try order.makeResponse()
    }
    
    func delete(_ request: Request, order: Order) throws -> ResponseRepresentable {
        try order.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, order: Order) throws -> ResponseRepresentable {
        let order: Order = try request.patchModel(order)
        try order.save()
        return try order.makeResponse()
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
