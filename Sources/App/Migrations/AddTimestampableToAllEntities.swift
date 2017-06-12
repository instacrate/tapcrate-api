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

        try? database.modify(Customer.self) { builder in
            builder.date(Customer.createdAtKey, default: Date())
            builder.date(Customer.updatedAtKey, default: Date())
        }
        try? database.modify(CustomerAddress.self) { builder in
            builder.date(CustomerAddress.createdAtKey, default: Date())
            builder.date(CustomerAddress.updatedAtKey, default: Date())
        }
        try? database.modify(Maker.self) { builder in
            builder.delete("createdOn")
            builder.date(Maker.createdAtKey, default: Date())
            builder.date(Maker.updatedAtKey, default: Date())
        }
        try? database.modify(Offer.self) { builder in
            builder.date(Offer.createdAtKey, default: Date())
            builder.date(Offer.updatedAtKey, default: Date())
        }
        try? database.modify(PageView.self) { builder in
            builder.date(PageView.createdAtKey, default: Date())
            builder.date(PageView.updatedAtKey, default: Date())
        }
        try? database.modify(CustomerPicture.self) { builder in
            builder.date(CustomerPicture.createdAtKey, default: Date())
            builder.date(CustomerPicture.updatedAtKey, default: Date())
        }
        try? database.modify(MakerPicture.self) { builder in
            builder.date(MakerPicture.createdAtKey, default: Date())
            builder.date(MakerPicture.updatedAtKey, default: Date())
        }
        try? database.modify(ProductPicture.self) { builder in
            builder.date(ProductPicture.createdAtKey, default: Date())
            builder.date(ProductPicture.updatedAtKey, default: Date())
        }
        try? database.modify(Product.self) { builder in
            builder.delete("created")
            builder.date(Product.createdAtKey, default: Date())
            builder.date(Product.updatedAtKey, default: Date())
        }
        try? database.modify(Review.self) { builder in
            builder.delete("date")
            builder.date(Review.createdAtKey, default: Date())
            builder.date(Review.updatedAtKey, default: Date())
        }
        try? database.modify(Subscription.self) { builder in
            builder.date(Subscription.createdAtKey, default: Date())
            builder.date(Subscription.updatedAtKey, default: Date())
        }
        try? database.modify(Tag.self) { builder in
            builder.date(Tag.createdAtKey, default: Date())
            builder.date(Tag.updatedAtKey, default: Date())
        }
        try? database.modify(Variant.self) { builder in
            builder.date(Variant.createdAtKey, default: Date())
            builder.date(Variant.updatedAtKey, default: Date())
        }
    }
}
