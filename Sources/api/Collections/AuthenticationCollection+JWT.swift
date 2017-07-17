//
//  AuthenticationCollection+JWT.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import Node
import HTTP
import JWT

final class ProviderData: NodeConvertible {
    
    public let uid: String?
    public let displayName: String
    public let photoURL: String?
    public let email: String
    public let providerId: String?
    
    init(node: Node) throws {
        uid = try node.extract("uid")
        displayName = try node.extract("displayName")
        photoURL = try node.extract("photoURL")
        email = try node.extract("email")
        providerId = try node.extract("providerId")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "displayName" : .string(displayName),
            "email" : .string(email),
        ]).add(objects: [
            "uid" : uid,
            "photoURL" : photoURL,
            "providerId" : providerId
        ])
    }
}

protocol JWTInitializable {

    var sub_id: String? { get }
    
    init(subject: String, request: Request) throws
}

extension String {
    
    func extractRSACertificate() -> Bytes {
        var certificate = self
        certificate = certificate.replacingOccurrences(of: "\n", with: "")
        certificate = certificate.replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
        certificate = certificate.replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
        return certificate.bytes.base64Decoded
    }
}

public struct IssuedAtClaimComparison: TimeBasedClaim {
    public static var name = "iat"
    
    public let createTimestamp: () -> Seconds
    public let leeway: Seconds
    
    public init(
        createTimestamp: @escaping () -> Seconds,
        leeway: Seconds = 0) {
        self.createTimestamp = createTimestamp
        self.leeway = leeway
    }
    
    public func verify(_ other: Seconds) -> Bool {
        return other + leeway >= value
    }
}
