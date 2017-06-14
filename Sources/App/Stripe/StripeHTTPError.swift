//
//  StripeHTTPError.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import Vapor
import HTTP

public struct StripeHTTPError: AbortError {
    public let status: HTTP.Status
    public let reason: String
    public let metadata: Node?

    init(node: Node, code: Status, resource: String) {
        self.metadata = node
        self.status = code
        self.reason = "Stripe Error at \(resource)"
    }
}

