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
	func authorize(identity: ATProtoOAuthClient.AuthIdentity) async throws
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

	//not going to implement, defer to the session
	//sessionStorage

	var didCache: [ATProtoDID: DiDCacheEntry] = [:]
	var protectedResourceCache: [String: CacheEntry<ProtectedResourceMetadata>] = [:]
	var authServerCache: [String: CacheEntry<ServerMetadata>] = [:]

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
