//
//  TrackingCollection.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 4/28/17.
//
//

import HTTP
import Routing
import Vapor
import Node
import Foundation
import Fluent

class TrackingCollection: EmptyInitializable, RouteCollection {
    
    required init() {}
    
    func build(_ builder: RouteBuilder) {
        
        builder.post("views") { request in
            let customer_id = try request.customer().throwableId()
            let pageView: PageView = try request.extractModel(injecting: Node(customer_id))
            try pageView.save()
            
            return Response(status: .ok)
        }
        
        builder.group("offerClicks") { builder in
            
            builder.post() { request in
                let customer = try request.customer()
                
                guard let json = request.json else {
                    throw Abort.custom(status: .badRequest, message: "Missing JSON body.")
                }
                
                guard let offer_id: Identifier = try? json.extract("offer_id"), let offer = try Offer.find(offer_id) else {
                    throw Abort.custom(status: .badRequest, message: "offer_id is not valid...")
                }
                
                try Pivot<Offer, Customer>(offer, customer).save()
                return Response(status: .ok)
            }
            
            builder.get() { request in
                let customer = try request.customer()
                return try customer.offers().all().makeResponse()
            }
        }
    }
}
