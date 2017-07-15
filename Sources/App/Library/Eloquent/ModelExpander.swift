//
//  ModelExpander.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 6/30/17.
//

import Vapor
import HTTP
import Fluent
import FluentProvider

struct Relation {

    let type: Model.Type
    let name: String
    let path: String

    init(parent: Model.Type) {
        type = parent
        name = parent.idKey
        path = parent.entity
    }

    init(child: Model.Type) {
        type = child
        name = child.idKey
        path = child.entity
    }
}

protocol Expandable {

    static func expandableParents() -> [Relation]?
}

extension Expandable {

    static func expandableParents() -> [Relation]? {
        return nil
    }
}

func collect<R: Model, B: Model, Identifier: StructuredDataWrapper>(identifiers: [Identifier], base: B.Type, relation: Relation) throws -> [[R]] {
    let ids: [Node] = try identifiers.converted(in: jsonContext)
    let models = try R.makeQuery().filter(.subset(relation.name, .in, ids)).all()

    return identifiers.map { (id: Identifier) -> [R] in
        return models.filter {
            let node = (try? $0.id.makeNode(in: emptyContext)) ?? Node.null
            return node.wrapped == id.wrapped
        }
    }
}

struct Expander<T: BaseModel>: QueryInitializable {

    static var key: String {
        return "expand"
    }

    let expandKeyPaths: [String]

    init(node: Node) throws {
        expandKeyPaths = node.string?.components(separatedBy: ",") ?? []
    }

    func expand<N: StructuredDataWrapper, T: BaseModel>(for models: [T], mappings: @escaping (Relation, [N]) throws -> [[NodeRepresentable]]) throws -> Node {
        let ids = try models.map { try $0.id().converted(to: N.self) }

        guard let expandlableRelationships = T.expandableParents() else {
            throw Abort.custom(status: .badRequest, message: "Could not find any expandable relationships on \(T.self).")
        }

        let relationships = try expandKeyPaths.map { (path: String) -> (Relation, [[NodeRepresentable]]) in
            guard let relation = expandlableRelationships.filter({ $0.path == path }).first else {
                throw Abort.custom(status: .badRequest, message: "\(path) is not a valid expansion on \(T.self).")
            }

            return try (relation, mappings(relation, ids))
        }

        var result: [Node] = []

        for (index, owner) in models.enumerated() {
            var ownerNode = try owner.makeNode(in: jsonContext)

            for (relationship, allEntities) in relationships {
                let entities = allEntities[index]

                ownerNode[relationship.type.foreignIdKey] = nil

                if entities.count == 0 {
                    ownerNode[relationship.path] = Node.null
                } else if entities.count == 1 {
                    ownerNode[relationship.path] = try entities[0].converted(in: jsonContext)
                } else {
                    ownerNode[relationship.path] = try entities.converted(in: jsonContext)
                }

                result.append(ownerNode)
            }
        }

        return Node.array(result)
    }

    func expand<N: StructuredDataWrapper, T: BaseModel>(for model: T, mappings: @escaping (Relation, N) throws -> [NodeRepresentable]) throws -> Node {
        let node = try expand(for: [model], mappings: { (relation, identifiers: [N]) -> [[NodeRepresentable]] in
            return try [mappings(relation, identifiers[0])]
        })

        // If it is a one element array, remove the array
        return node.array?.first ?? node
    }
}
