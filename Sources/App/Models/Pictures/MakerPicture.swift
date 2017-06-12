//
//  MakerPicture.swift
//  App
//
//  Created by Hakon Hanesand on 6/11/17.
//

import Vapor
import FluentProvider

final class MakerPicture: PictureBase {

    let storage = Storage()

    static var permitted: [String] = ["maker_id", "url"]

    let maker_id: Identifier
    let url: String

    static func pictures(for owner: Identifier) throws -> Query<MakerPicture> {
        return try self.makeQuery().filter("maker_id", owner.int)
    }

    init(node: Node) throws {
        url = try node.extract("url")

        if let context = node.context as? ParentContext<Maker> {
            maker_id = context.parent_id
        } else {
            maker_id = try node.extract("maker_id")
        }

        id = try? node.extract("id")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "maker_id" : maker_id,
            MakerPicture.createdAtKey : createdAt,
            MakerPicture.updatedAtKey : updatedAt
        ])
    }

    class func prepare(_ database: Database) throws {
        try database.create(MakerPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.parent(Maker.self)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(MakerPicture.self)
    }
}

extension MakerPicture: Protected {

    func owner() throws -> ModelOwner {
        return .maker(id: maker_id)
    }
}
