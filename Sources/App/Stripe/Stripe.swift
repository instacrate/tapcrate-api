//
//  Stripe.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/23/16.
//
//

import JSON
import HTTP
import Transport
import Vapor
import Foundation

fileprivate func merge(query: [String: NodeRepresentable?], with metadata: [String: NodeRepresentable]) -> [String: NodeRepresentable] {
    var arguments = metadata.map { (arg: (key: String, value: NodeRepresentable)) -> (String, NodeRepresentable) in
        let (key, value) = arg
        return ("metadata[\(key)]", value)
    }

    arguments.append(contentsOf: query.filter { (arg) -> Bool in
        return arg.value != nil
    }.map { (arg: ((key: String, value: NodeRepresentable))) -> (String, NodeRepresentable) in
        return (arg.key, arg.value)
    })

    return Dictionary(uniqueKeysWithValues: arguments)
}

public final class Stripe {

    public static let publicToken = "pk_test_lGLXGH2jjEx7KFtPmAYz39VA"
    private static let secretToken = "sk_test_WceGrEBqnYpjCYF6exFBXvnf"

    private static let base = HTTPClient(baseURL: "https://api.stripe.com/v1/", publicToken, secretToken)
    private static let uploads = HTTPClient(baseURL: "https://uploads.stripe.com/v1/", publicToken, secretToken)

    public static func createToken() throws -> Token {
        return try base.post("tokens", query: ["card[number]" : 4242424242424242, "card[exp_month]" : 12, "card[exp_year]" : 2017, "card[cvc]" : 123])
    }
    
    public static func createToken(for customer: String, representing card: String, on account: String = Stripe.publicToken) throws -> Token {
        return try base.post("tokens", query: ["customer" : customer, "card" : card], token: account)
    }

    public static func createNormalAccount(email: String, source: String, local_id: Int?, on account: String = Stripe.secretToken) throws -> StripeCustomer {
        let defaultQuery = ["source" : source]
        let query = local_id.flatMap { merge(query: defaultQuery, with: ["id" : "\($0)"]) } ?? defaultQuery

        return try base.post("customers", query: query, token: account)
    }

    public static func createManagedAccount(email: String, local_id: Int?) throws -> StripeAccount {
        let defaultQuery: [String: NodeRepresentable] = ["managed" : true, "country" : "US", "email" : email, "legal_entity[type]" : "company"]
        let query = local_id.flatMap { merge(query: defaultQuery, with: ["id" : "\($0)"]) } ?? defaultQuery
        return try base.post("accounts", query: query, token: Stripe.secretToken)
    }

    public static func associate(source: String, withStripe id: String, under secretKey: String = Stripe.secretToken) throws -> Card {
        return try base.post("customers/\(id)/sources", query: ["source" : source], token: secretKey)
    }

    public static func createPlan(with price: Double, name: String, interval: Interval, on account: String = Stripe.publicToken) throws -> Plan {
        let parameters = ["id" : "\(UUID().uuidString)", "amount" : "\(Int(price * 100))", "currency" : "usd", "interval" : interval.rawValue, "name" : name]
        return try base.post("plans", query: parameters, token: account)
    }
    
    public static func update(customer id: String, parameters: [String : String]) throws-> StripeCustomer {
        return try base.post("customer/\(id)", query: parameters)
    }

    public static func subscribe(user userId: String, to planId: String, with frequency: Interval = .month, oneTime: Bool, cut: Double, coupon: String? = nil, metadata: [String : NodeRepresentable], under publishableKey: String) throws -> StripeSubscription {
        let subscription: StripeSubscription = try base.post("subscriptions", query: merge(query: ["customer" : userId, "plan" : planId, "application_fee_percent" : cut, "coupon" : coupon], with: metadata), token: publishableKey)

        if oneTime {
            let json = try base.delete("/subscriptions/\(subscription.id)", query: ["at_period_end" : true])

            guard json["cancel_at_period_end"]?.bool == true else {
                throw Abort.custom(status: .internalServerError, message: json.makeNode(in: emptyContext).object?.description ?? "Fuck.")
            }
        }

        return subscription
    }
    
    public static func charge(source: String, for price: Double, withFee percent: Double, under account: String = Stripe.publicToken) throws -> Charge {
        return try base.post("charges", query: ["amount" : Int(price * 100), "currency" : "USD", "application_fee" : Int(price * percent * 100), "source" : source], token: account)
    }
    
    public static func createCoupon(code: String) throws -> StripeCoupon {
        return try base.post("coupons", query: ["duration": Duration.once.rawValue, "id" : code, "percent_off" : 5, "max_redemptions" : 1])
    }

    public static func paymentInformation(for customer: String, under account: String = Stripe.secretToken) throws -> [Card] {
        return try base.getList("customers/\(customer)/sources", query: ["object" : "card"], token: account)
    }

    public static func customerInformation(for customer: String) throws -> StripeCustomer {
        return try base.get("customers/\(customer)")
    }
    
    public static func makerInformation(for maker: String) throws -> StripeAccount {
        return try base.get("accounts/\(maker)")
    }
    
    public static func transfers(for secretKey: String) throws -> [Transfer] {
        return try base.getList("transfers", token: secretKey)
    }

    public static func delete(payment: String, from customer: String) throws -> JSON {
        return try base.delete("customers/\(customer)/sources/\(payment)")
    }

    public static func disputes() throws -> [Dispute] {
        return try base.getList("disputes")
    }

    public static func verificationRequiremnts(for country: CountryCode) throws -> Country {
        return try base.get("country_specs/\(country.rawValue.uppercased())")
    }

    public static func acceptedTermsOfService(for user: String, ip: String) throws -> StripeAccount {
        return try base.post("accounts/\(user)", query: ["tos_acceptance[date]" : "\(Int(Date().timeIntervalSince1970))", "tos_acceptance[ip]" : ip])
    }

    public static func updateInvoiceMetadata(for id: Int, invoice_id: String) throws -> Invoice {
        return try base.post("invoices/\(invoice_id)", query: ["metadata[orders]" : "\(id)"])
    }
    
    public static func updateAccount(id: String, parameters: [String : String]) throws -> StripeAccount {
        return try base.post("accounts/\(id)", query: parameters)
    }

    public static func checkForError(in json: JSON, from resource: String) throws {
        if json["error"] != nil {
            throw StripeHTTPError(node: json.node, code: .internalServerError, resource: resource)
        }
    }
}
