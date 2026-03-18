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
	func authorize(
		identity: AtprotoOAuthClient.AuthIdentity
	) async throws -> SessionState.Archive
}

public struct AtprotoOAuthClient: Sendable {
	static let logger = Logger(
		subsystem: "com.germnetwork",
		category: "AtprotoOAuthClient")

	public nonisolated let appCredentials: AppCredentials
	public let userAuthenticator: UserAuthenticator
	public let resourceFetcher: HTTPFetcher
	let authFetcher: HTTPFetcher
//	public let atprotoClient: AtprotoClient

	//didResolver
	//handleResolver

	public init(
		appCredentials: AppCredentials,
		userAuthenticator: @escaping UserAuthenticator,
		resourceFetcher: HTTPFetcher,
		authFetcher: HTTPFetcher,
//		atprotoClient: AtprotoClient
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.resourceFetcher = resourceFetcher
//		self.atprotoClient = atprotoClient
		self.authFetcher = authFetcher
	}
}
