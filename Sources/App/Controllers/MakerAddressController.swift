//
//  MakerAddressController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/13/17.
//
//

import Vapor
import HTTP

final class MakerAddressController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let maker = try request.maker()
        return try maker.addresses().all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let address: MakerAddress = try request.extractModel(injecting: request.makerInjectable())

        try Maker.ensure(action: .create, isAllowedOn: address, by: request)
        try address.save()
        
        return try address.makeResponse()
    }
    
    func delete(_ request: Request, address: MakerAddress) throws -> ResponseRepresentable {
        try Maker.ensure(action: .delete, isAllowedOn: address, by: request)

        try address.delete()
        
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, address: MakerAddress) throws -> ResponseRepresentable {
        try Maker.ensure(action: .read, isAllowedOn: address, by: request)
        
        let updated: MakerAddress = try request.patchModel(address)
        try updated.save()
        
        return try updated.makeResponse()
    }
    
    func makeResource() -> Resource<MakerAddress> {
        return Resource(
            index: index,
            store: create,
            update: modify,
            destroy: delete
        )
    }
}
