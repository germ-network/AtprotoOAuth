import AtprotoTypes
import Foundation
import GermConvenience

/// Agent
///
/// All fetching should be done through an agent, i.e. AtprotoSession.
///
/// AtprotoOAuthSession conforms to AtprotoSession and uses OAuth functionality for authed calls
/// AtprotoMockSession conforms to AtprotoSession and returns mocks for authed and unauthed calls
///  - Should also properly mock a server instance
/// AtprotoSessionImpl conforms to AtprotoSession and throws on authed calls
///
public protocol AtprotoSession {
	func authResponse(for request: URLRequest) async throws -> HTTPDataResponse
}
