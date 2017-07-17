//
//  StripeWebhookCollection.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import HTTP
import Routing
import Vapor
import FluentProvider

func extractFrom<T: Model>(metadata: Node) throws -> T? {
    let identifier = metadata[T.entity]?.converted(to: Identifier.self)
    return try identifier.flatMap { try T.find($0) }
}

struct StripeWebhookCollection {

    static let triggerStrings = [
        "legal_entity.verification.document",
        "legal_entity.additional_owners.0.verification.document",
        "legal_entity.additional_owners.1.verification.document",
        "legal_entity.additional_owners.2.verification.document",
        "legal_entity.additional_owners.3.verification.document"
    ]

    static func listenForStripeWebhookEvents() {

        StripeWebhookManagerCollection.shared.registerHandler(forResource: .account, action: .updated) { (event) -> Response in
            guard let account = event.data.object as? StripeAccount else {
                throw Abort.custom(status: .internalServerError, message: "Failed to parse the account from the account.updated event.")
            }

            guard let id: Identifier = try account.metadata.extract("id"), let maker = try Maker.find(id) else {
                throw Abort.custom(status: .internalServerError, message: "Missing connected vendor for account with id \(account.id)")
            }

            maker.missingFields = account.verification.fields_needed.count > 0
            maker.needsIdentityUpload = StripeWebhookCollection.triggerStrings.map { account.verification.fields_needed.contains($0) }.reduce(false) { $0 || $1 }
            try maker.save()

            return Response(status: .ok)
        }

        StripeWebhookManagerCollection.shared.registerHandler(forResource: .subscription, action: .created) { (event) -> Response in

//            guard let subscription = event.data.object as? Subscription else {
//                throw Abort.custom(status: .internalServerError, message: "Failed to parse the invoice from the invoice.created event.")
//            }
//
//            guard
//                let subscription: Subscription = try extractFrom(metadata: invoice.metadata),
//                let maker: Maker = try extractFrom(metadata: invoice.metadata),
//                let customer: Customer = try extractFrom(metadata: invoice.metadata),
//                let shipping: CustomerAddress = try extractFrom(metadata: invoice.metadata),
//                let product: Product = try extractFrom(metadata: invoice.metadata)
//            else {
//                throw Abort.custom(status: .internalServerError, message: "Wrong or missing metadata \(invoice.metadata)")
//            }

//            var order = Order(with: subscription.id, vendor_id: vendor.id, box_id: box.id, shipping_id: shipping.id, customer_id: customer.id, order_id: invoice.id)
//            try order.save()

//            let _ = try Stripe.updateInvoiceMetadata(for: order.id!.int!, invoice_id: invoice.id)

            return Response(status: .ok)
        }
    }
}
