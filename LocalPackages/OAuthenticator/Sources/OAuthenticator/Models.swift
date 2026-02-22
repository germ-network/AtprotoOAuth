import Foundation
import OAuth

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

/// Function that can execute a `URLRequest`.
///
/// This is used to abstract the actual networking system from the underlying authentication
/// mechanism.
public typealias URLResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)

public struct AppCredentials: Codable, Hashable, Sendable {
	public var clientId: String
	public var scopes: [String]
	public var callbackURL: URL

	public init(clientId: String, scopes: [String], callbackURL: URL) {
		self.clientId = clientId
		self.scopes = scopes
		self.callbackURL = callbackURL
	}

	public var callbackURLScheme: String {
		get throws {
			guard let scheme = callbackURL.scheme else {
				throw AuthenticatorError.missingScheme
			}

			return scheme
		}
	}
}

public struct LoginStorage: Sendable {
	public typealias RetrieveLogin = @Sendable () async throws -> SessionState?
	public typealias StoreLogin = @Sendable (SessionState) async throws -> Void
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

public struct PARConfiguration: Hashable, Sendable {
	public let url: URL
	public let parameters: [String: String]

	public init(url: URL, parameters: [String: String] = [:]) {
		self.url = url
		self.parameters = parameters
	}
}

public struct TokenHandling: Sendable {
	public enum ResponseStatus: Hashable, Sendable {
		case valid
		case refresh
		case authorize
		case refreshOrAuthorize
	}

	public struct AuthorizationURLParameters: Sendable {
		public let credentials: AppCredentials
		public let pcke: PKCEVerifier?
		public let parRequestURI: String?
		public let stateToken: String
		public let responseProvider: URLResponseProvider
	}

	public struct LoginProviderParameters: Sendable {
		public let authorizationURL: URL
		public let credentials: AppCredentials
		public let redirectURL: URL
		public let responseProvider: URLResponseProvider
		public let stateToken: String
		public let pcke: PKCEVerifier?

		public init(
			authorizationURL: URL,
			credentials: AppCredentials,
			redirectURL: URL,
			responseProvider: @escaping URLResponseProvider,
			stateToken: String,
			pcke: PKCEVerifier?
		) {
			self.authorizationURL = authorizationURL
			self.credentials = credentials
			self.redirectURL = redirectURL
			self.responseProvider = responseProvider
			self.stateToken = stateToken
			self.pcke = pcke
		}
	}

	/// The output of this is a URL suitable for user authentication in a browser.
	public typealias AuthorizationURLProvider =
		@Sendable (AuthorizationURLParameters) async throws -> URL

	/// A function that processes the results of an authentication operation
	///
	/// URL: The result of the Configuration.UserAuthenticator function
	/// AppCredentials: The credentials from Configuration.appCredentials
	/// URL: the authenticated URL from the OAuth service
	/// URLResponseProvider: the authenticator's provider
	public typealias LoginProvider =
		@Sendable (LoginProviderParameters) async throws -> SessionState
	public typealias RefreshProvider =
		@Sendable (SessionState, AppCredentials, URLResponseProvider) async throws ->
		SessionState
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
