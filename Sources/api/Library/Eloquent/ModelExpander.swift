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
    let isMany: Bool

    init(parent: Model.Type) {
        type = parent
        name = parent.idKey
        path = parent.entity
        isMany = false
    }

    init(child: Model.Type, path: String? = nil, hasMany: Bool = true) {
        type = child
        name = child.idKey
        self.path = path ?? child.entity
        isMany = hasMany
    }

    init(type: Model.Type, path: String, isMany: Bool = false) {
        self.type = type
        self.path = path
        name = type.entity
        self.isMany = isMany
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

    func expand<N: StructuredDataWrapper, T: BaseModel>(for models: [T], mappings: @escaping (Relation, [N]) throws -> [[NodeRepresentable]]) throws -> [Node] {
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
                } else if entities.count == 1 && !relationship.isMany {
                    ownerNode[relationship.path] = try entities[0].makeNode(in: jsonContext)
                } else {
                    ownerNode[relationship.path] = try Node.array(entities.map { try $0.makeNode(in: jsonContext) })
                }
            }

            result.append(ownerNode)
        }

        return result
    }

    func expand<N: StructuredDataWrapper, T: BaseModel>(for model: T, mappings: @escaping (Relation, N) throws -> [NodeRepresentable]) throws -> Node {
        let node = try expand(for: [model], mappings: { (relation, identifiers: [N]) -> [[NodeRepresentable]] in
            return try [mappings(relation, identifiers[0])]
        })

        if node.count == 0 {
            return Node.null
        } else if node.count == 1 {
            return node[0]
        } else {
            return Node.array(node)
        }
    }
}
