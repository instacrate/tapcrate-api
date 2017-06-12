//
//  CustomerShippingController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Vapor
import HTTP

final class CustomerShippingController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        return try customer.shippingAddresses().all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let address: CustomerAddress = try request.extractModel(injecting: request.customerInjectable())

        try CustomerAddress.ensure(action: .create, isAllowedOn: address, by: request)
        try address.save()
        
        return try address.makeResponse()
    }
    
    func delete(_ request: Request, address: CustomerAddress) throws -> ResponseRepresentable {
        try CustomerAddress.ensure(action: .create, isAllowedOn: address, by: request)

        try address.delete()
        
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, address: CustomerAddress) throws -> ResponseRepresentable {
        try CustomerAddress.ensure(action: .create, isAllowedOn: address, by: request)
        
        let updated: CustomerAddress = try request.patchModel(address)
        try updated.save()
        
        return try updated.makeResponse()
    }
    
    func makeResource() -> Resource<CustomerAddress> {
        return Resource(
            index: index,
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
