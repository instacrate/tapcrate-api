import HTTP
import Node
import Vapor
import FluentProvider

extension StructuredDataWrapper {

    public func permit(_ keys: [String]) -> Self {
        guard var object = wrapped.object else {
            return self
        }

        object.forEach { (arg) in
            let (key, _) = arg

            if !keys.contains(key) {
                object[key] = nil
            }
        }

        return Self(object, in: jsonContext)
    }
}

extension Sanitizable where Self: NodeInitializable {

    init(sanitizing node: Node, in context: Context = emptyContext) throws {
        var sanitized = node.permit(Self.permitted)
        sanitized.context = context
        try self.init(node: sanitized)
    }
}

extension Request {

    public func extractModel<M: Model>() throws -> M where M: Sanitizable & NodeConvertible  {
        return try extractModel(injecting: Node.null)
    }

    public func extractModel<M: Model>(injecting: Node) throws -> M where M: Sanitizable & NodeConvertible {
        var json = try self.json().permit(M.permitted)

        injecting.object?.forEach { (arg) in
            let (key, value) = arg
            json[key] = JSON(value)
        }

        let model = try M(node: json)

        return model
    }

    public func patchModel<M: Model>(id: NodeRepresentable) throws -> M where M: Sanitizable & NodeConvertible {
        guard let model = try M.find(id) else {
            throw Abort.notFound
        }

        return try patchModel(model)
    }

    public func patchModel<M: Model>(_ model: M) throws -> M where M: Sanitizable & NodeConvertible {
        guard let json = json?.permit(M.permitted).wrapped.object else {
            throw Abort.badRequest
        }

        var modelJSON = try model.makeNode(in: rowContext)
        json.forEach { modelJSON[$0.key] = Node($0.value) }

        let model = try M(node: modelJSON)
        model.exists = true

        return model
    }
}
