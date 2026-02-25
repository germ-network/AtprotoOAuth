import ATProtoClient
import ATProtoTypes
import Foundation
import OAuth
import os

public protocol ATProtoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> ATProtoDID

	typealias UnauthPDSRequest<Result: Sendable> =
		@Sendable (
			URL,
			@escaping HTTPURLResponseProvider
		) async throws -> Result
	//MARK: Unauthenticated Pass-through
	func fetchFromPDS<Result: Sendable>(
		did: ATProtoDID,
		request: UnauthPDSRequest<Result>
	) async throws -> Result

	//MARK: Authentication
	func authorize(identity: ATProtoOAuthClient.AuthIdentity) async throws
		-> SessionState.Archive
}

public actor ATProtoOAuthClient {
	static let logger = Logger(
		subsystem: "com.germnetwork",
		category: "BlueskyOAuthenticator")

	public let appCredentials: AppCredentials
	public typealias UserAuthenticator = @Sendable (URL, String) async throws -> URL
	public let userAuthenticator: UserAuthenticator
	public let responseProvider: HTTPURLResponseProvider
	public let atprotoClient: ATProtoClientInterface

	//didResolver
	//handleResolver
	//stateStorage

	//not going to implement, defer to the session
	//sessionStorage
	var protectedResourceCache: [String: CacheEntry<ProtectedResourceMetadata>] = [:]
	var authServerCache: [String: CacheEntry<ServerMetadata>] = [:]

	public init(
		appCredentials: AppCredentials,
		userAuthenticator: @escaping UserAuthenticator,
		responseProvider: @escaping HTTPURLResponseProvider,
		atprotoClient: ATProtoClientInterface,
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.responseProvider = responseProvider
		self.atprotoClient = atprotoClient
	}
}
