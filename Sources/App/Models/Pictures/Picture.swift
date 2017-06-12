//
//  Picture.swift
//  App
//
//  Created by Hakon Hanesand on 6/11/17.
//

import Vapor
import FluentProvider

protocol PictureBase: Model, NodeConvertible, Sanitizable, Preparation, Protected {

    static func pictures(for owner: Identifier) throws -> Query<Self>
}
