//
//  TagController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

final class TagController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Tag.all().makeResponse()
    }
    
    func show(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        return try tag.products().all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let tag: Tag = try request.extractModel()
        try tag.save()
        return try tag.makeResponse()
    }
    
    func delete(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        try tag.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        let tag: Tag = try request.patchModel(tag)
        try tag.save()
        return try tag.makeResponse()
    }
    
    func makeResource() -> Resource<Tag> {
        return Resource(
            index: index,
            store: create,
            show: show,
            update: modify,
            destroy: delete
        )
    }
}
