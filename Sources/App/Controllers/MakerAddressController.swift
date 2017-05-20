//
//  MakerAddressController.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/13/17.
//
//

import Vapor
import HTTP

extension MakerAddress {
    
    func shouldAllow(request: Request) throws {
        guard let maker = try? request.maker() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource MakerAddress(\(throwableId())) by this maker. Must be logged in as Maker(\(maker_id.int ?? 0)).")
        }
        
        guard maker.id?.int == maker_id.int else {
            throw try Abort.custom(status: .forbidden, message: "This Maker(\(maker.throwableId())) does not have access to resource MakerAddress(\(throwableId()). Must be logged in as Maker(\(maker_id.int ?? 0).")
        }
    }
}

final class MakerAddressController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let maker = try request.maker()
        return try maker.addresses().all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let address: MakerAddress = try request.extractModel(injecting: request.makerInjectable())
        try address.save()
        
        return try address.makeResponse()
    }
    
    func delete(_ request: Request, address: MakerAddress) throws -> ResponseRepresentable {
        try address.shouldAllow(request: request)
        try address.delete()
        
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, address: MakerAddress) throws -> ResponseRepresentable {
        try address.shouldAllow(request: request)
        
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
