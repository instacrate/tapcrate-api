//
//  Contexts.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 6/30/17.
//

import Vapor
import HTTP
import Fluent
import FluentProvider

public struct ParentContext<Parent: Entity>: Context {

    public let parent_id: Identifier

    init(_ parent: Identifier?) throws {
        guard let identifier = parent else {
            throw Abort.custom(status: .internalServerError, message: "Parent context does not have id")
        }

        parent_id = identifier
    }
}

public struct SecondaryParentContext<Parent: Entity, Secondary: Entity>: Context {

    public let parent_id: Identifier
    public let secondary_id: Identifier

    init(_ _parent: Identifier?, _ _secondary: Identifier?) throws {
        guard let parent = _parent else {
            throw Abort.custom(status: .internalServerError, message: "Parent context does not have parent id")
        }

        guard let secondary = _secondary else {
            throw Abort.custom(status: .internalServerError, message: "Parent context does not have secondary id")
        }

        self.parent_id = parent
        self.secondary_id = secondary
    }
}
