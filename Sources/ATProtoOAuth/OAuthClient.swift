import ATProtoClient
import ATProtoTypes
import Foundation
import OAuthenticator

public protocol ATProtoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> ATProtoDID

	typealias UnauthPDSRequest<Result: Sendable> =
		@Sendable (
			URL,
			@escaping URLResponseProvider
		) async throws -> Result
	//MARK: Unauthenticated Pass-through
	func fetchFromPDS<Result: Sendable>(
		did: ATProtoDID,
		request: UnauthPDSRequest<Result>
	) async throws -> Result

	//MARK: Authentication
	func initialLogin(handle: String) async throws
		-> ATProtoOAuthSession.Archive
}

public actor ATProtoOAuthClient {
	public let clientId: String
	public let userAuthenticator: Authenticator.UserAuthenticator
	public let responseProvider: URLResponseProvider
	public let atprotoClient: ATProtoClientInterface

	//didResolver
	//handleResolver
	//stateStorage

	//not going to implement
	//sessionStorage

	var didCache: [ATProtoDID: CacheEntry] = [:]
	var hostCache: [String: CacheState<ProtectedResourceMetadata>] = [:]

	public init(
		clientId: String,
		userAuthenticator: @escaping Authenticator.UserAuthenticator,
		authenticationStatusHandler: Authenticator.AuthenticationStatusHandler? = nil,
		responseProvider: @escaping URLResponseProvider,
		atprotoClient: ATProtoClientInterface,
	) {
		self.clientId = clientId
		self.userAuthenticator = userAuthenticator
		self.responseProvider = responseProvider
		self.atprotoClient = atprotoClient
	}
}

extension ATProtoOAuthClient {
	public enum AuthIdentity: Sendable {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(ATProtoDID, String?)
	}
}
