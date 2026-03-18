import AtprotoTypes
import Foundation
import GermConvenience

/// Agent
///
/// All fetching should be done through an agent
///
/// AtprotoOAuthAgent conforms to AtprotoAgent and uses OAuth functionality for authed calls
/// AtprotoMockAgent conforms to AtprotoAgent and returns mocks for authed and unauthed calls
///  - Should also properly mock a server instance
/// AtprotoAgentImpl conforms to AtprotoAgent and throws on authed calls
///
/// Have a method on it that declares whether or not it can do auth
///
public protocol AtprotoAgent {
	var repo: Atproto.DID { get }
	var allowsAuthedCalls: Bool { get }
	func response(_ request: AtprotoAgentRequest) async throws -> HTTPDataResponse
	func authResponse(_ request: AtprotoAgentRequest) async throws -> HTTPDataResponse
}

public struct AtprotoAgentRequest: Sendable {
	let relativePath: String
	let queryItems: [URLQueryItem]
	let httpMethod: HTTPMethod
	let httpBody: Data?
}

enum AtprotoAgentError: Error {
	case authedCallsNotPermitted
}

extension AtprotoAgentError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .authedCallsNotPermitted: "Authed calls not permitted"
		}
	}
}
