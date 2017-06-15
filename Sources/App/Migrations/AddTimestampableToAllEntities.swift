//
//  AddTimestampableToAllEntities.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import Fluent

struct AddTimestampableToAllEntities: Preparation {

    static func revert(_ database: Database) throws {

    }

    static func prepare(_ database: Database) throws {
        try database.modify(Subscription.self) { builder in
            builder.parent(Customer.self, optional: true)
            builder.date(Subscription.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Subscription.updatedAtKey, default: "2017-04-28 14:46:17")
        }
    }
}
