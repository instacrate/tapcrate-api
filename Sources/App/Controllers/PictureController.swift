//
//  PictureController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/8/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider
import Routing

protocol NestedResourceController {

    associatedtype ParentType: Model
    associatedtype NestedType: Model

    func index(_ request: Request, parent_id: Identifier) throws -> ResponseRepresentable
    func create(_ request: Request, parent_id: Identifier) throws -> ResponseRepresentable
    func delete(_ request: Request, parent_id: Identifier, nested_id: Identifier) throws -> ResponseRepresentable
}

extension RouteBuilder {
    
    func nested<ControllerType: NestedResourceController>(base path: String, controller: ControllerType) {
        self.add(.get, path, "\(ControllerType.ParentType.parameter)", "pictures") { request in
            guard let owner_id: Identifier = try request.parameters[ControllerType.ParentType.uniqueSlug]?.converted() else {
                throw RouterError.invalidParameter
            }
            
            return try controller.index(request, parent_id: owner_id).makeResponse()
        }
        
        self.add(.post, path, "\(ControllerType.ParentType.parameter)", "pictures") { request in
            guard let owner_id: Identifier = try request.parameters[ControllerType.ParentType.uniqueSlug]?.converted() else {
                throw RouterError.invalidParameter
            }
            
            return try controller.create(request, parent_id: owner_id).makeResponse()
        }
        
        self.add(.delete, path, "\(ControllerType.ParentType.parameter)", "pictures", "\(ControllerType.NestedType.parameter)") { request in
            guard let owner_id: Identifier = try request.parameters[ControllerType.ParentType.uniqueSlug]?.converted() else {
                throw RouterError.invalidParameter
            }
            
            guard let nested_id: Identifier = try request.parameters[ControllerType.NestedType.uniqueSlug]?.converted() else {
                throw RouterError.invalidParameter
            }
            
            return try controller.delete(request, parent_id: owner_id, nested_id: nested_id).makeResponse()
        }
    }
}

final class PictureController<OwnerType: Model, PictureType: PictureBase>: NestedResourceController {

    typealias ParentType = OwnerType
    typealias NestedType = PictureType

    func index(_ request: Request, parent_id: Identifier) throws -> ResponseRepresentable {
        return try PictureType.pictures(for: parent_id).all().makeResponse()
    }

    func createPicture(from node: Node, ownedBy owner: Identifier, with request: Request) throws -> PictureType {
        let context = try ParentContext<OwnerType>(owner)

        let picture = try PictureType(node: Node(node.permit(PictureType.permitted).wrapped, in: context))
        try PictureType.ensure(action: .create, isAllowedOn: picture, by: request)
        try picture.save()

        return picture
    }

    func create(_ request: Request, parent_id: Identifier) throws -> ResponseRepresentable {
        guard let node = request.json?.node else {
            throw Abort.custom(status: .badRequest, message: "Missing json.")
        }

        if let array = node.array {
            return try Node.array(array.map {
                try createPicture(from: $0, ownedBy: parent_id, with: request).makeNode(in: jsonContext)
            }).makeResponse()
        } else {
            return try createPicture(from: node, ownedBy: parent_id, with: request).makeResponse()
        }
    }
    
    func delete(_ request: Request, parent_id: Identifier, nested_id: Identifier) throws -> ResponseRepresentable {
        guard let picture = try PictureType.find(nested_id) else {
            throw Abort.custom(status: .badRequest, message: "No such picture exists.")
        }

        try PictureType.ensure(action: .delete, isAllowedOn: picture, by: request)
        
        try picture.delete()
        return Response(status: .noContent)
    }
}

