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
public protocol AtprotoAgent: Sendable {
	var repo: Atproto.DID { get }
	var allowsAuthedCalls: Bool { get }
	var resolver: AtprotoResolver { get }
	func response(_ request: AtprotoAgentRequest) async throws
		-> GermConvenience.HTTPDataResponse
	func authResponse(_ request: AtprotoAgentRequest) async throws
		-> GermConvenience.HTTPDataResponse
}

public struct AtprotoAgentRequest: Sendable {
	public let relativePath: String
	public let queryItems: [URLQueryItem]
	public let httpMethod: HTTPMethod
	public let httpBody: Data?
	public let contentTypeValue: String?
	public let acceptValue: String?

	public init(
		relativePath: String,
		queryItems: [URLQueryItem],
		httpMethod: HTTPMethod,
		httpBody: Data?,
		contentTypeValue: String?,
		acceptValue: String?
	) {
		self.relativePath = relativePath
		self.queryItems = queryItems
		self.httpMethod = httpMethod
		self.httpBody = httpBody
		self.contentTypeValue = contentTypeValue
		self.acceptValue = acceptValue
	}

	public init(
		relativePath: String,
		queryItems: [URLQueryItem],
		httpMethod: HTTPMethod,
		acceptValue: String?
	) {
		self.relativePath = relativePath
		self.queryItems = queryItems
		self.httpMethod = httpMethod
		self.httpBody = nil
		self.contentTypeValue = nil
		self.acceptValue = acceptValue
	}
}

enum AtprotoAgentError: Error {
	case authedCallsNotPermitted
}

extension AtprotoAgentError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .authedCallsNotPermitted: "Authed calls not permitted on this agent"
		}
	}
}
