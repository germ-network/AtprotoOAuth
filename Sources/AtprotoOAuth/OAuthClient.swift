import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import OAuth
import os

public protocol ATProtoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> Atproto.DID

	//MARK: Authentication
	//want to end up with a valid archive, not a live object
	func authorize(identity: ATProtoOAuthClient.AuthIdentity) async throws
		-> SessionState.Archive
}

public actor ATProtoOAuthClient {
	static let logger = Logger(
		subsystem: "com.germnetwork",
		category: "BlueskyOAuthenticator")

	public nonisolated let appCredentials: AppCredentials
	public typealias UserAuthenticator = @Sendable (URL, String) async throws -> URL
	public let userAuthenticator: UserAuthenticator
	public let responseProvider: HTTPDataResponse.Requester
	public let atprotoClient: ATProtoClientInterface

	//didResolver
	//handleResolver
	//stateStorage

	public init(
		appCredentials: AppCredentials,
		userAuthenticator: @escaping UserAuthenticator,
		responseProvider: @escaping HTTPDataResponse.Requester,
		atprotoClient: ATProtoClientInterface,
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.responseProvider = responseProvider
		self.atprotoClient = atprotoClient
	}
}
