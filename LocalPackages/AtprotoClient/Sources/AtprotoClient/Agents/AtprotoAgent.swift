import AtprotoTypes
import Foundation
import GermConvenience

/// Agent
///
/// All fetching should be done through an agent, i.e. AtprotoSession.
///
/// AtprotoOAuthAgent conforms to AtprotoSession and uses OAuth functionality for authed calls
/// AtprotoMockAgent conforms to AtprotoSession and returns mocks for authed and unauthed calls
///  - Should also properly mock a server instance
/// AtprotoAgentImpl conforms to AtprotoSession and throws on authed calls
///
/// Have a method on it that declares whether or not it can do auth
///
public protocol AtprotoAgent {
	func authResponse(for request: URLRequest) async throws -> HTTPDataResponse
}
