//
//  Main.swift
//  polymyr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node
import HTTP
import AuthProvider
import Foundation

public final class PasswordAuthenticationMiddleware__<U: PasswordAuthenticatable>: Middleware {
    public let passwordVerifier: PasswordVerifier?
    public init(
        _ userType: U.Type = U.self,
        _ passwordVerifier: PasswordVerifier? = nil
        ) {
        self.passwordVerifier = passwordVerifier
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        
        guard let password = req.auth.header?.basic else {
            throw AuthenticationError.invalidCredentials
        }
        
        let u = try U.authenticate(password)
        
        req.auth.authenticate(u)
        
        return try next.respond(to: req)
    }
}

let drop = Droplet.create()

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

Date.incomingDateFormatters.append(formatter)

drop.group(middleware: [PersistMiddleware(Customer.self), PersistMiddleware(Maker.self)]) { persistable in
    
    AuthenticationCollection().build(persistable)
    
    persistable.resource("makers", MakerController())
    persistable.picture(base: "makers", slug: "makers_id", picture: PictureController<MakerPicture, Maker>())
    persistable.resource("makerAddresses", MakerAddressController())
    
    persistable.resource("customers", CustomerController())
    persistable.picture(base: "customers", slug: "customer_id", picture: PictureController<CustomerPicture, Customer>())
    persistable.resource("customerAddresses", CustomerShippingController())
    
    persistable.resource("products", ProductController())
    persistable.picture(base: "products", slug: "products_id", picture: PictureController<ProductPicture, Product>())
    
    persistable.resource("tags", TagController())
    try! persistable.collection(DescriptionCollection.self)
    
    persistable.resource("offers", OfferController())
    try! persistable.collection(TrackingCollection.self)
    
    persistable.resource("orders", OrderController())
    persistable.resource("variants", VariantController())
    
    StripeCollection().build(persistable)
    DescriptionCollection().build(persistable)
    
    persistable.get("search") { request in
        return try Product.makeQuery().all().map { $0.name }.makeResponse()
    }
}

print(drop.router.routes)

do {
    try drop.run()
} catch {
    fatalError("Error while running droplet : \(error)")
}
