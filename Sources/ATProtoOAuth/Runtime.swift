import ATProtoClient
import ATProtoTypes
import OAuthenticator

public protocol ATProtoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> ATProtoDID

	//MARK: Authentication
	func initialLogin(handle: String) async throws
		-> ATProtoOAuthSession.Archive
}

public actor ATProtoOAuthRuntime {
	public let appCredentials: AppCredentials
	public let userAuthenticator: Authenticator.UserAuthenticator
	public let mode: Authenticator.UserAuthenticationMode
	public let responseProvider: URLResponseProvider
	public let atprotoClient: ATProtoClientInterface

	var didCache: [ATProtoDID: CacheEntry] = [:]
	var hostCache: [String: CacheState<ProtectedResourceMetadata>] = [:]

	public init(
		appCredentials: AppCredentials,
		mode: Authenticator.UserAuthenticationMode = .automatic,
		userAuthenticator: @escaping Authenticator.UserAuthenticator,
		authenticationStatusHandler: Authenticator.AuthenticationStatusHandler? = nil,
		responseProvider: @escaping URLResponseProvider,
		atprotoClient: ATProtoClientInterface,
	) {
		self.appCredentials = appCredentials
		self.userAuthenticator = userAuthenticator
		self.mode = mode
		self.responseProvider = responseProvider
		self.atprotoClient = atprotoClient
	}
}

extension ATProtoOAuthRuntime {
	public enum AuthIdentity: Sendable {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(ATProtoDID, String?)
	}
}
