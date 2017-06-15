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
            builder.date(Customer.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Customer.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(CustomerAddress.self) { builder in
            builder.date(CustomerAddress.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(CustomerAddress.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Maker.self) { builder in
            builder.delete("createdOn")
            builder.date(Maker.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Maker.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Offer.self) { builder in
            builder.date(Offer.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Offer.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(PageView.self) { builder in
            builder.date(PageView.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(PageView.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(CustomerPicture.self) { builder in
            builder.date(CustomerPicture.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(CustomerPicture.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(MakerPicture.self) { builder in
            builder.date(MakerPicture.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(MakerPicture.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(ProductPicture.self) { builder in
            builder.date(ProductPicture.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(ProductPicture.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Product.self) { builder in
            builder.delete("created")
            builder.date(Product.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Product.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Review.self) { builder in
            builder.delete("date")
            builder.date(Review.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Review.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Subscription.self) { builder in
            builder.parent(Customer.self)
            builder.date(Subscription.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Subscription.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Tag.self) { builder in
            builder.date(Tag.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Tag.updatedAtKey, default: "2017-04-28 14:46:17")
        }
        try? database.modify(Variant.self) { builder in
            builder.date(Variant.createdAtKey, default: "2017-04-28 14:46:17")
            builder.date(Variant.updatedAtKey, default: "2017-04-28 14:46:17")
        }
    }
}
