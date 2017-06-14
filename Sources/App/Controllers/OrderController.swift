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

extension Stripe {
    
    static func charge(order: inout Order) throws {
        
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
            
            let stripeSubscription = try Stripe.subscribe(user: customer, to: plan, oneTime: false, cut: maker.cut, metadata: [:], under: secret)
            
            item.subscribed = true
            item.subcriptionIdentifier = stripeSubscription.id
            try item.save()
        }
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let type: SessionType = try request.extract()

        switch type {
        case .customer:
            let orders = try request.customer().orders().all()
            
            if orders.count == 0 {
                return try Node.array([]).makeResponse()
            }
            
            let orderIds = try orders.map { $0.id!.int! }.unique().converted(to: Array<Node>.self, in: jsonContext)
            let subscriptions = try Subscription.makeQuery().filter(.subset(Order.foreignIdKey, .in, orderIds)).all()
            
            let groupedSubscriptions = subscriptions.group() {
                return $0.order_id.int!
            }
            
            let addressIds = try orders.map { $0.customer_address_id.int! }.unique().converted(to: Array<Node>.self, in: jsonContext)
            let addresses = try CustomerAddress.makeQuery().filter(.subset(CustomerAddress.idKey, .in, addressIds)).all()
            
            let makerIds = try subscriptions.map { $0.maker_id.int! }.unique().converted(to: Array<Node>.self, in: jsonContext)
            let makers = try Maker.makeQuery().filter(.subset(Maker.idKey, .in, makerIds)).all()
            
            var result: [Node] = []
            
            for order in orders {
                guard let subscriptions = groupedSubscriptions[order.id!.int!] else {
                    continue
                }
                
                var subscriptionsNode: [Node] = []
                
                for subscription in subscriptions {
                    let maker = makers.filter { $0.id!.int! == subscription.maker_id.int }.first
                    
                    var subscriptionNode = try subscription.makeNode(in: jsonContext)
                    try subscriptionNode.replace(relation: "maker", with: maker.makeNode(in: jsonContext))
                    subscriptionsNode.append(subscriptionNode)
                }

                var orderNode = try order.makeNode(in: jsonContext)
                orderNode["subscriptions"] = try subscriptionsNode.makeNode(in: jsonContext)
                
                let address = addresses.filter { $0.id!.int! == order.customer_address_id.int }.first
                try orderNode.replace(relation: "customer_address", with: address.makeNode(in: jsonContext))
                
                result.append(orderNode)
            }
            
            return try result.makeResponse()
            
        case .maker:
            var query = try request.maker().subscriptions().makeQuery()

            if let fulfilled = request.query?["fulfilled"]?.bool {
                query = try query.filter("fulfilled", fulfilled)
            }
            
            let subscriptions = try query.all()
            
            if subscriptions.count == 0 {
                return try Node.array([]).makeResponse()
            }
            
            let groupedSubscriptions = subscriptions.group() {
                return $0.order_id.int!
            }
            
            let subIds = try Array(groupedSubscriptions.keys).converted(to: Array<Node>.self, in: jsonContext)
            let orders = try Order.makeQuery().filter(.subset(Order.idKey, .in, subIds)).all()
            
            let addressIds = try orders.map { $0.customer_address_id.int! }.unique().converted(to: Array<Node>.self, in: jsonContext)
            let addresses = try CustomerAddress.makeQuery().filter(.subset(CustomerAddress.idKey, .in, addressIds)).all()
            
            let customerIds = try orders.map { $0.customer_id.int! }.unique().converted(to: Array<Node>.self, in: jsonContext)
            let customers = try Customer.makeQuery().filter(.subset(Customer.idKey, .in, customerIds)).all()
            
            var result: [Node] = []
            
            for order in orders {
                var orderNode = try order.makeNode(in: jsonContext)
                orderNode["subscriptions"] = try groupedSubscriptions[order.id!.int!].makeNode(in: jsonContext)
                
                let address = addresses.filter { $0.id!.int! == order.customer_address_id.int }.first
                try orderNode.replace(relation: "customer_address", with: address.makeNode(in: jsonContext))
                
                let customer = customers.filter { $0.id!.int! == order.customer_id.int }.first
                try orderNode.replace(relation: "customer", with: customer.makeNode(in: jsonContext))
                
                result.append(orderNode)
            }
            
            return try result.makeResponse()
        case .anonymous:
            return try Order.all().makeResponse()
        }
    }
    
    func show(_ request: Request, order: Order) throws -> ResponseRepresentable {
        
        let type: SessionType = try request.extract()
        try Order.ensure(action: .read, isAllowedOn: order, by: request)
        
        switch type {
        case .customer: fallthrough
        case .anonymous:
            return try order.makeResponse()
            
        case .maker:
            let subscriptions = try order.items().all()
            let address = try order.address().all()[0]
            let customer = try order.customer().all()[0]
        
            var orderNode = try order.makeNode(in: jsonContext)
        
            try orderNode["subscriptions"] = subscriptions.makeNode(in: jsonContext)
            try orderNode.replace(relation: "customer_address", with: address.makeNode(in: jsonContext))
            try orderNode.replace(relation: "customer", with: customer.makeNode(in: jsonContext))
        
            return try orderNode.makeResponse()
        }
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var order = try Order.createOrder(for: request)
        try Stripe.charge(order: &order)
        return try order.makeResponse()
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create,
            show: show
        )
    }
}
