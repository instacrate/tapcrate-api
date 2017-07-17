//
//  Protected.swift
//  App
//
//  Created by Hakon Hanesand on 6/10/17.
//

import HTTP
import FluentProvider
import Node

enum ActionType {
    
    case read
    case write
    case create
    case delete

    static let all: [ActionType] = [.read, .write, .create, .delete]
}

struct ModelOwner: Equatable {

    let modelType: Model.Type
    let id: Identifier

    static func ==(lhs: ModelOwner, rhs: ModelOwner) -> Bool {
        return lhs.modelType == rhs.modelType && lhs.id == rhs.id
    }

    var explained: String {
        return "\(String(describing: modelType))(\(id))"
    }
}

extension Request {

    func sessionAuthenticatedUser(for type: SessionType) -> Entity? {
        switch type {
        case .maker:
            return try? self.maker()

        case .customer:
            return try? self.customer()
        }
    }

    func allAuthenticatedTypes() throws -> [ModelOwner] {
        var authenticated: [ModelOwner] = []

        if
            let customer = self.multipleUserAuth.authenticated(Customer.self),
            let owner = try? ModelOwner(modelType: Customer.self, id: customer.id())
        {
            authenticated.append(owner)
        }

        if
            let maker = self.multipleUserAuth.authenticated(Maker.self),
            let owner = try? ModelOwner(modelType: Maker.self, id: maker.id())
        {
            authenticated.append(owner)
        }

        return authenticated
    }
}

protocol Protected {

    func owners() throws -> [ModelOwner]

    // Defaults to create
    var actionsAllowedForPublic: [ActionType] { get }

    // Defaults to all actions
    var actionsAllowedForOwner: [ActionType] { get }

    @discardableResult
    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws -> Bool
}

extension Protected where Self: Model {

    var actionsAllowedForPublic: [ActionType] {
        return [.create]
    }

    var actionsAllowedForOwner: [ActionType] {
        return ActionType.all
    }

    @discardableResult
    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws -> Bool {
        if action == .create {
            // Allow everyone to create
            return true
        }

        let owners = try model.owners()
        let sessions = try request.allAuthenticatedTypes()

        let hasOwningSession = owners.contains { sessions.contains($0) }

        if hasOwningSession && model.actionsAllowedForOwner.contains(action) {
            return true
        } else if !hasOwningSession && model.actionsAllowedForPublic.contains(action) {
            return true
        }

        throw try Abort.custom(status: .unauthorized, message: "You can not access \(type(of: model))(\(model.id().int ?? 0)). It is owned by \(model.owners().map { $0.explained }.joined(separator: ", ")), while you are authenticated as \(request.allAuthenticatedTypes().map { $0.explained }.joined(separator: ", "))")
    }
}

