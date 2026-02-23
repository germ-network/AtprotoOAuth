import Foundation
import OAuth

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

public struct LoginStorage: Sendable {
	public typealias RetrieveLogin = @Sendable () async throws -> SessionStateShim?
	public typealias StoreLogin = @Sendable (SessionStateShim) async throws -> Void
	public typealias ClearLogin = @Sendable () async throws -> Void

	public let retrieveLogin: RetrieveLogin
	public let storeLogin: StoreLogin
	public let clearLogin: ClearLogin

	public init(
		retrieveLogin: @escaping RetrieveLogin,
		storeLogin: @escaping StoreLogin,
		clearLogin: @escaping ClearLogin = {}
	) {
		self.retrieveLogin = retrieveLogin
		self.storeLogin = storeLogin
		self.clearLogin = clearLogin
	}
}

public struct TokenHandling: Sendable {
	public enum ResponseStatus: Hashable, Sendable {
		case valid
		case refresh
		case authorize
		case refreshOrAuthorize
	}

	/// A function that processes the results of an authentication operation
	///
	/// URL: The result of the Configuration.UserAuthenticator function
	/// AppCredentials: The credentials from Configuration.appCredentials
	/// URL: the authenticated URL from the OAuth service
	/// URLResponseProvider: the authenticator's provider
	public typealias LoginProvider =
		@Sendable (LoginProviderParameters) async throws -> SessionStateShim
	public typealias RefreshProvider =
		@Sendable (SessionStateShim, AppCredentials, URLResponseProvider) async throws ->
		SessionStateShim
	public typealias ResponseStatusProvider =
		@Sendable ((Data, URLResponse)) throws -> ResponseStatus

	public let authorizationURLProvider: AuthorizationURLProvider
	public let loginProvider: LoginProvider
	public let refreshProvider: RefreshProvider?
	public let responseStatusProvider: ResponseStatusProvider
	public let dpopJWTGenerator: DPoPSigner.JWTGenerator?
	public let parConfiguration: PARConfiguration?
	public let pkce: PKCEVerifier?

	public init(
		parConfiguration: PARConfiguration? = nil,
		authorizationURLProvider: @escaping AuthorizationURLProvider,
		loginProvider: @escaping LoginProvider,
		refreshProvider: RefreshProvider? = nil,
		responseStatusProvider: @escaping ResponseStatusProvider = Self
			.refreshOrAuthorizeWhenUnauthorized,
		dpopJWTGenerator: DPoPSigner.JWTGenerator? = nil,
		pkce: PKCEVerifier? = nil

	) {
		self.authorizationURLProvider = authorizationURLProvider
		self.loginProvider = loginProvider
		self.refreshProvider = refreshProvider
		self.responseStatusProvider = responseStatusProvider
		self.dpopJWTGenerator = dpopJWTGenerator
		self.parConfiguration = parConfiguration
		self.pkce = pkce
	}

	@Sendable
	public static func allResponsesValid(result: (Data, URLResponse)) throws -> ResponseStatus {
		return .valid
	}

	@Sendable
	public static func refreshOrAuthorizeWhenUnauthorized(result: (Data, URLResponse)) throws
		-> ResponseStatus
	{
		guard let response = result.1 as? HTTPURLResponse else {
			throw AuthenticatorError.httpResponseExpected
		}

		if response.statusCode == 401 {
			return .refresh
		}

		return .valid
	}
}
