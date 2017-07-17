//
//  TaxCollection.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import HTTP
import Routing
import Vapor
import Node
import Foundation
import Fluent

extension QueryRepresentable where Self: ExecutorRepresentable {

    public func fetchFirst() throws -> E {
        guard let result = try first() else {
            throw Abort.custom(status: .badRequest, message: "could not find model for type \(E.self)")
        }

        return result
    }
}

struct TaxResult: NodeRepresentable {

    let price: Double
    let rate: Double
    let tax: Double
    let totalPrice: Double

    init(price: Double, rate: Double) {
        self.price = price
        self.rate = rate
        self.tax = price * rate
        self.totalPrice = price + self.tax
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "price" : price,
            "rate" : rate,
            "tax" : tax,
            "totalPrice" : totalPrice
        ])
    }
}

class TaxCollection: EmptyInitializable, RouteCollection {

    required init() {}

    func build(_ builder: RouteBuilder) {

        builder.post("tax") { request in
            let json = try request.json()

            guard
                let maker = (try? Maker.find(json.extract("makerId") as Identifier)) ?? nil,
                let product = (try? Product.find(json.extract("productId") as Identifier)) ?? nil,
                let customerAddress = (try? CustomerAddress.find(json.extract("customerAddressId") as Identifier)) ?? nil
            else {
                throw Abort.custom(status: .badRequest, message: "Missing or invalid makerId, productId, or customerAddressId.")
            }

            let makerAddress = try maker.addresses().fetchFirst()

            if customerAddress.state != makerAddress.state {
                // https://developers.taxjar.com/api/guides/#avoiding-unnecessary-api-calls
                return try TaxResult(price: product.fullPrice, rate: 0.0).makeResponse()
            }

            return try TaxResult(price: product.fullPrice, rate: 0.0).makeResponse()
        }
    }
}
