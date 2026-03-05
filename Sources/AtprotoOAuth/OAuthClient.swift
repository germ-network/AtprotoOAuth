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
	public let httpRequester: HTTPDataResponse.Requester
	let manualRedirectFetcher: HTTPDataResponse.Requester
	public let atprotoClient: AtprotoClientInterface
	let oauthMetadataFetcher: OAuthMetadataFetcher

	//didResolver
	//handleResolver

	public init(
		appCredentials: AppCredentials,
		userAuthenticator: @escaping UserAuthenticator,
		responseProvider: @escaping HTTPDataResponse.Requester,
		manualRedirectFetcher: @escaping HTTPDataResponse.Requester,
		atprotoClient: AtprotoClientInterface,
		oauthMetadataFetcher: OAuthMetadataFetcher,
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.httpRequester = responseProvider
		self.atprotoClient = atprotoClient
		self.oauthMetadataFetcher = oauthMetadataFetcher
		self.manualRedirectFetcher = manualRedirectFetcher
	}
}
