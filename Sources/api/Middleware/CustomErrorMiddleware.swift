//
//  CustomErrorMiddleware.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import Vapor
import HTTP

public final class CustomErrorMiddleware: Middleware {

    let log: LogProtocol

    public init(_ log: LogProtocol) {
        self.log = log
    }

    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: req)
        } catch {
            log.error(error)
            return make(with: req, for: error)
        }
    }

    public func make(with req: Request, for error: Error) -> Response {
        let status = Status(error)
        let response = Response(status: status)
        response.json = JSON(error)
        return response
    }
}

extension CustomErrorMiddleware: ConfigInitializable {
    public convenience init(config: Config) throws {
        let log = try config.resolveLog()
        self.init(log)
    }
}

extension Status {
    internal init(_ error: Error) {
        if let abort = error as? AbortError {
            self = abort.status
        } else {
            self = .internalServerError
        }
    }
}


extension JSON {
    fileprivate init(_ error: Error) {
        let status = Status(error)

        var json = JSON(["error": true])
        if let abort = error as? AbortError {
            json.set("reason", abort.reason)
        } else {
            json.set("reason", status.reasonPhrase)
        }

        if let abort = error as? AbortError {
            json.set("metadata", abort.metadata)
        }

        if let debug = error as? Debuggable {
            json.set("debugReason", debug.reason)
            json.set("identifier", debug.fullIdentifier)
            json.set("possibleCauses", debug.possibleCauses)
            json.set("suggestedFixes", debug.suggestedFixes)
            json.set("documentationLinks", debug.documentationLinks)
            json.set("stackOverflowQuestions", debug.stackOverflowQuestions)
            json.set("gitHubIssues", debug.gitHubIssues)
        }

        self = json
    }
}

extension StructuredDataWrapper {
    fileprivate mutating func set(_ key: String, _ closure: (Context?) throws -> Node) rethrows {
        let node = try closure(context)
        set(key, node)
    }

    fileprivate mutating func set(_ key: String, _ value: String?) {
        guard let value = value, !value.isEmpty else { return }
        set(key, .string(value))
    }

    fileprivate mutating func set(_ key: String, _ node: Node?) {
        guard let node = node else { return }
        self[key] = Self(node, context)
    }

    fileprivate mutating func set(_ key: String, _ array: [String]?) {
        guard let array = array?.map(StructuredData.string).map(Self.init), !array.isEmpty else { return }
        self[key] = .array(array)
    }
}

extension StructuredDataWrapper {
    // TODO: I expected this, maybe put in node
    init(_ node: Node, _ context: Context) {
        self.init(node: node.wrapped, in: context)
    }
}

extension Debuggable {
    var loggable: String {
        var print: [String] = []

        print.append("\(Self.readableName): \(reason)")
        print.append("Identifier: \(fullIdentifier)")

        if !possibleCauses.isEmpty {
            print.append("Possible Causes: \(possibleCauses.commaSeparated)")
        }

        if !suggestedFixes.isEmpty {
            print.append("Suggested Fixes: \(suggestedFixes.commaSeparated)")
        }

        if !documentationLinks.isEmpty {
            print.append("Documentation Links: \(documentationLinks.commaSeparated)")
        }

        if !stackOverflowQuestions.isEmpty {
            print.append("Stack Overflow Questions: \(stackOverflowQuestions.commaSeparated)")
        }

        if !gitHubIssues.isEmpty {
            print.append("GitHub Issues: \(gitHubIssues.commaSeparated)")
        }

        return print.map { "[\($0)]" }.joined(separator: " ")
    }
}

extension Sequence where Iterator.Element == String {
    var commaSeparated: String {
        return joined(separator: ", ")
    }
}

