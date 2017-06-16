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
    case shared(members: [ModelOwner])
    case any

    func matches(entity _entity: Entity?) -> Bool {
        guard let entity = _entity else {
            return false
        }

        switch self {
        case .any:
            return true

        case let .maker(id) where entity is Maker:
            return (try? entity.id() == id) ?? false
        case let .customer(id) where entity is Customer:
            return (try? entity.id() == id) ?? false

        case let .shared(members):
            for owner in members {
                if owner.matches(entity: entity) {
                    return true
                }
            }

            return false

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

        case let .shared(members):
            return members.map { $0.explained }.joined(separator: ", ")
        }
    }
}

extension Request {

    func authenticatedEntity(for modelOwner: SessionType) -> Entity? {
        switch modelOwner {
        case .anonymous:
            return nil

        case .maker:
            return try? self.maker()

        case .customer:
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

    func owners() throws -> [ModelOwner]

    // Defaults to create
    var actionsAllowedForPublic: [ActionType] { get }

    // Defaults to all actions
    var actionsAllowedForOwner: [ActionType] { get }

    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws -> Bool
    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by subject: SessionType, on request: Request) throws -> Bool
}

extension Protected where Self: Model {

    var actionsAllowedForPublic: [ActionType] {
        return [.create]
    }

    var actionsAllowedForOwner: [ActionType] {
        return ActionType.all
    }
    
    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by request: Request) throws -> Bool {
        if
            let _ = try? request.customer(),
            let allowed = try? ensure(action: action, isAllowedOn: model, by: .customer, on: request),
            allowed
        {
            return true
        }

        if
            let _ = try? request.maker(),
            let allowed = try? ensure(action: action, isAllowedOn: model, by: .maker, on: request),
            allowed
        {
            return true
        }

        return try ensure(action: action, isAllowedOn: model, by: .anonymous, on: request)
    }

    static func ensure<ModelType: Protected & Model>(action: ActionType, isAllowedOn model: ModelType, by subject: SessionType, on request: Request) throws -> Bool {
        guard let owners = try? model.owners() else {
            if action != .create {
                throw Abort.custom(status: .unauthorized, message: "Can only create.")
            }

            return true
        }

        for owner in owners {
            let requester = request.authenticatedEntity(for: subject)
            let allowedActions: [ActionType]

            if owner.matches(entity: requester) {
                allowedActions = model.actionsAllowedForOwner
            } else {
                allowedActions = model.actionsAllowedForPublic
            }

            if allowedActions.contains(action) {
                return true
            }
        }

        throw try Abort.custom(status: .unauthorized, message: "You can not access \(type(of: model))(\(model.id().int ?? 0)). It is owned by \(model.owners().map { $0.explained }.joined(separator: ", ")), while you are authenticated as \(request.allAuthenticatedTypes().map { $0.explained }.joined(separator: ", "))")
    }
}

