import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import OAuth
import os

public protocol AtprotoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> Atproto.DID

	//MARK: Authentication
	//want to end up with a valid archive, not a live object
	func authorize(identity: AtprotoOAuthClient.AuthIdentity) async throws
		-> SessionState.Archive
}

public struct AtprotoOAuthClient: Sendable {
	static let logger = Logger(
		subsystem: "com.germnetwork",
		category: "BlueskyOAuthenticator")

	public nonisolated let appCredentials: AppCredentials
	public typealias UserAuthenticator = @Sendable (URL, String) async throws -> URL
	public let userAuthenticator: UserAuthenticator
	public let responseProvider: HTTPDataResponse.Requester
	public let atprotoClient: AtprotoClientInterface

	//didResolver
	//handleResolver
	//stateStorage

	public init(
		appCredentials: AppCredentials,
		userAuthenticator: @escaping UserAuthenticator,
		responseProvider: @escaping HTTPDataResponse.Requester,
		atprotoClient: AtprotoClientInterface,
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.responseProvider = responseProvider
		self.atprotoClient = atprotoClient
	}
}
