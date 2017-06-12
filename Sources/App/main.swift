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

let drop = Droplet.create()

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

Date.incomingDateFormatters.append(formatter)

let persist: [Middleware] = [
    MultipleUserPersistMiddleware(Customer.self),
    MultipleUserPersistMiddleware(Maker.self)
]

drop.group(middleware: persist) { persistable in
    
    AuthenticationCollection().build(persistable)
    
    persistable.resource("makers", MakerController())
    persistable.nested(base: "makers", controller: PictureController<Maker, MakerPicture>())
    persistable.resource("makerAddresses", MakerAddressController())
    
    persistable.resource("customers", CustomerController())
    persistable.nested(base: "customers", controller: PictureController<Customer, CustomerPicture>())
    persistable.resource("customerAddresses", CustomerShippingController())
    
    persistable.resource("products", ProductController())
    persistable.nested(base: "products", controller: PictureController<Product, ProductPicture>())
    
    persistable.resource("reviews", ReviewController())
    
    persistable.resource("tags", TagController())
    try! persistable.collection(DescriptionCollection.self)
    
    persistable.resource("offers", OfferController())
    try! persistable.collection(TrackingCollection.self)
    
    persistable.resource("orders", OrderController())
    persistable.resource("variants", VariantController())
    
    StripeCollection().build(persistable)
    DescriptionCollection().build(persistable)
    TagCollection().build(persistable)
    
    persistable.get("search") { request in
        return try Product.makeQuery().all().map { $0.name }.makeResponse()
    }
}

do {
    try drop.run()
} catch {
    fatalError("Error while running droplet : \(error)")
}
