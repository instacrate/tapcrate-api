//
//  HTTPClient.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import JSON
import HTTP
import Foundation
import Vapor

func createBasicAuthHeader(for token: String, includeTrailingColon: Bool = false) throws -> [HeaderKey: String] {
    let base64 = token.bytes.base64Encoded
    return ["Authorization" : "Basic \(base64.makeString())\(includeTrailingColon ? ":" : "")"]
}

final class HTTPClient {

    let baseURLString: String

    let publicToken: String
    let secretToken: String

    init(baseURL: String, _ publicToken: String, _ secretToken: String) {
        baseURLString = baseURL
        self.publicToken = publicToken
        self.secretToken = secretToken
    }
    
    func checkForError(in json: JSON, from resource: String) throws {
        if json["error"] != nil {
            throw StripeHTTPError(node: json.node, code: .internalServerError, resource: resource)
        }
    }

    func get<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:]) throws -> T {
        return try get(resource, query: query, token: secretToken)
    }

    func get<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String) throws -> T {
        let response = try drop.client.get(baseURLString + resource, query: query, createBasicAuthHeader(for: token))

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        try checkForError(in: json, from: resource)

        return try T.init(node: json.makeNode(in: emptyContext))
    }

    func getList<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:]) throws -> [T] {
        return try getList(resource, query: query, token: secretToken)
    }

    func getList<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String) throws -> [T] {
        let response = try drop.client.get(baseURLString + resource, query: query, createBasicAuthHeader(for: token))

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        try checkForError(in: json, from: resource)

        guard let objects = json.node["data"]?.array else {
            throw Abort.custom(status: .internalServerError, message: "Unexpected response formatting. \(json)")
        }

        return try objects.map {
            return try T.init(node: $0)
        }
    }

    func post<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:]) throws -> T {
        return try post(resource, query: query, token: secretToken)
    }

    func post<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String) throws -> T {
        let response = try drop.client.post(baseURLString + resource, query: query, createBasicAuthHeader(for: token))

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        try checkForError(in: json, from: resource)

        return try T.init(node: json.makeNode(in: emptyContext))
    }

    func delete(_ resource: String, query: [String : NodeRepresentable] = [:]) throws -> JSON {
        return try delete(resource, query: query, token: secretToken)
    }

    func delete(_ resource: String, query: [String : NodeRepresentable] = [:], token: String) throws -> JSON {
        let response = try drop.client.delete(baseURLString + resource, query: query, createBasicAuthHeader(for: token))

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        try checkForError(in: json, from: resource)

        return json
    }
}
