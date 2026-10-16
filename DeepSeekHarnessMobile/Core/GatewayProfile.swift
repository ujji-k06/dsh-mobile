import Foundation

struct GatewayProfile: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var gatewayId: String?
    var gatewayName: String
    var alias: String?
    var endpoints: [String]
    var preferredEndpoint: String?
    var remoteDeviceId: String?
    var lastConnectedAt: Date?
    var deviceKind: String = "desktopcomputer"

    var displayName: String { alias?.isEmpty == false ? alias! : gatewayName }
    var connectionEndpoints: [String] {
        var result: [String] = []
        for value in [preferredEndpoint].compactMap({ $0 }) + endpoints where endpoints.contains(value) {
            if !result.contains(value) { result.append(value) }
        }
        return result
    }
}

enum GatewayIdentity {
    static func isValid(_ value: String) -> Bool {
        value.range(of: "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", options: .regularExpression) != nil
    }

    static func validate(expected: String?, received: String?) throws {
        if let received, !isValid(received) { throw GatewayProfileError.identity }
        if let expected, expected.lowercased() != received?.lowercased() {
            throw GatewayProfileError.identity
        }
    }

    static func endpoint(_ value: String) throws -> String {
        guard value.count <= 2048, var parts = URLComponents(string: value),
              let host = parts.host?.lowercased(), !host.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              !["0.0.0.0", "::", "[::]"].contains(host) else { throw GatewayProfileError.address }
        let scheme = parts.scheme?.lowercased()
        guard scheme == "ws" || scheme == "wss" else { throw GatewayProfileError.address }
        if scheme == "ws", !isLocal(host) { throw GatewayProfileError.address }
        parts.scheme = scheme
        parts.host = host
        if parts.path.isEmpty { parts.path = "/ws/mobile" }
        guard let url = parts.url else { throw GatewayProfileError.address }
        return url.absoluteString
    }

    static func isLocal(_ host: String) -> Bool {
        let host = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if host == "localhost" || host == "::1" || host.hasSuffix(".local") { return true }
        if host.contains(":"), host.hasPrefix("fc") || host.hasPrefix("fd") || host.hasPrefix("fe80:") { return true }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        let octets = parts.compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ (0...255).contains($0) }) else { return false }
        return octets[0] == 10 || octets[0] == 127 ||
            (octets[0] == 192 && octets[1] == 168) ||
            (octets[0] == 172 && (16...31).contains(octets[1])) ||
            (octets[0] == 169 && octets[1] == 254)
    }

    static func endpoints(_ payload: GatewayPairingPayload) throws -> [String] {
        guard (payload.endpoints?.count ?? 0) <= 16 else { throw GatewayProfileError.address }
        var values: [String] = []
        for raw in [payload.publicUrl] + (payload.endpoints ?? []) {
            let value = try endpoint(raw)
            if !values.contains(value) { values.append(value) }
        }
        guard values.count <= 16 else { throw GatewayProfileError.address }
        return values
    }
}

enum GatewayProfileError: LocalizedError {
    case identity, address, conflict
    var errorDescription: String? {
        switch self {
        case .identity: "The gateway identity is missing, invalid, or doesn't match the saved host. The connection stopped; confirm the host and pair again."
        case .address: "The gateway address is invalid, or there are more than 16 candidate addresses. Public connections must use WSS, and the address can't contain credentials, query parameters, or a fragment."
        case .conflict: "This gateway identity already belongs to another host record. Pick the original record in the host list and pair again."
        }
    }
}
