//
//  Protected.swift
//  App
//
//  Created by Hakon Hanesand on 6/10/17.
//

import HTTP
import FluentProvider

enum ActionType {
    
    case read
    case write
    case create
    case delete

    static let all: [ActionType] = [.read, .write, .create, .delete]
}

enum ModelOwner {

    case customer(id: Identifier)
    case maker(id: Identifier)
    case any

    func matches(entity _entity: Entity?) throws -> Bool {
        guard let entity = _entity else {
            return false
        }

        switch self {
        case .any:
            return true

        case let .maker(id) where entity is Maker:
            return try entity.id() == id

        case let .customer(id) where entity is Customer:
            return try entity.id() == id

        default:
            return false
        }
    }

    var explained: String {
        switch self {
        case .any:
            return "Any"

        case let .maker(id):
            return "Maker(\(id.string ?? ""))"

        case let .customer(id):
            return "Customer(\(id.string ?? ""))"
        }
    }
}

extension Request {

    func authenticatedEntity(for modelOwner: ModelOwner) -> Entity? {
        switch modelOwner {
        case .any:
            return nil

        case .maker(_):
            return try? self.maker()

        case .customer(_):
            return try? self.customer()
        }
    }

    func allAuthenticatedTypes() throws -> [ModelOwner] {
        var authenticated: [ModelOwner] = []

        if let customer = self.multipleUserAuth.authenticated(Customer.self) {
            try authenticated.append(.customer(id: customer.id()))
        }

        if let maker = self.multipleUserAuth.authenticated(Maker.self) {
            try authenticated.append(.maker(id: maker.id()))
        }

        return authenticated
    }
}

protocol Protected {

    func owner() throws -> ModelOwner

    // Defaults to create
    var actionsAllowedForPublic: [ActionType] { get }

    // Defaults to all actions
    var actionsAllowedForOwner: [ActionType] { get }

    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws
}

extension Protected where Self: Model {

    var actionsAllowedForPublic: [ActionType] {
        return [.create]
    }

    var actionsAllowedForOwner: [ActionType] {
        return ActionType.all
    }
    
    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws {
        guard let owner = try? model.owner() else {
            if action != .create {
                throw Abort.custom(status: .unauthorized, message: "Can only create.")
            }

            return
        }

        let requester = request.authenticatedEntity(for: owner)
        let allowedActions: [ActionType]

        if try owner.matches(entity: requester) {
            allowedActions = model.actionsAllowedForOwner
        } else {
            allowedActions = model.actionsAllowedForPublic
        }

        if !allowedActions.contains(action) {
            throw try Abort.custom(status: .unauthorized, message: "You can not access \(type(of: model))(\(model.id().int ?? 0)). It is owned by \(model.owner().explained), while you are authenticated as \(request.allAuthenticatedTypes().map { $0.explained }.joined(separator: ", "))")
        }
    }
}

