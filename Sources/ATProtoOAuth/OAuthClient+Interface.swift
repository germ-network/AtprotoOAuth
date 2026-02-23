//
//  Runtime+Interface.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoTypes
import AuthenticationServices
import Crypto
import Foundation
import OAuth
import OAuthenticator

extension ATProtoOAuthClient: ATProtoOAuthInterface {
	public func fetchFromPDS<Result: Sendable>(
		did: ATProtoDID,
		request: UnauthPDSRequest<Result>
	) async throws -> Result {
		try await request(
			resolvePdsUrl(did: did),
			responseProvider
		)
	}

	//Germ will always do pre-processing so we will know did,
	//but you can start from handle
	public enum AuthIdentity: Sendable {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(ATProtoDID)

		var serverHint: String {
			switch self {
			case .handle(let string):
				string
			case .did(let did):
				did.fullId
			}
		}
	}

	public func authorize(
		identity: AuthIdentity
	) async throws -> SessionState.Archive {

		let did: ATProtoDID
		switch identity {
		case .did(let _did):
			did = _did
		case .handle(let handle):
			//resolve handle to pds, uncached
			did = try await Self.resolve(handle: handle)
		}

		//resolve pds and pds metadata
		let didDoc = try await resolveDidDocument(did: did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl = try await getAuthorizationUrl(
			didDoc: didDoc
		)

		guard
			let authorizationServerHost = authorizationServerUrl.host()
		else {
			throw OAuthClientError.missingUrlHost
		}

		let serverConfig = try await getAuthServerMetadata(host: authorizationServerHost)

		let dpopKey = P256.Signing.PrivateKey()

		//		let tokenHandling = Bluesky.tokenHandling(
		//			account: did.fullId,
		//			server: serverConfig,
		//			jwtGenerator: try dpopKey.makeDpopSigner(),
		//			validator: { tokenResponse, sub in
		//				// TODO: GER-1343 - Implement validator
		//				// after a token is issued, it is critical that the returned
		//				// identity be resolved and its PDS match the issuing server
		//				//
		//				// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
		//				return true
		//			}
		//		)

		let parConfig = PARConfiguration(
			url: URL(string: serverConfig.pushedAuthorizationRequestEndpoint)!,
			parameters: ["login_hint": identity.serverHint]
		)

		return
			try await ATProtoOAuthSession
			.performUserAuthentication(
				appCredentials: appCredentials,
				parConfig: parConfig,
				authEndpoint: serverConfig.authorizationEndpoint,
				//				authorizationURLProvider: Self.authorizationURLProvider(
				//					server: serverConfig
				//				),
				loginProvider: Self.loginProvider(
					server: serverConfig,
					validator: { tokenResponse, sub in
						// TODO: GER-1343 - Implement validator
						// after a token is issued, it is critical that the returned
						// identity be resolved and its PDS match the issuing server
						//
						// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
						return true
					}
				),
				userAuthenticator: { try await userAuthenticator($0, $1) }
			)
		//		let authenticator = Authenticator(
		//			config: .init(
		//				appCredentials: appCredentials,
		//				tokenHandling: tokenHandling,
		//				userAuthenticator: {
		//					try await ASWebAuthenticationSession.userAuthenticator(
		//						url: $0, scheme: $1)
		//				}
		//			)
		//		)
		//		let login = try await authenticator.authenticate()
		//
		//		return SessionState(
		//			accessToken: login.accessToken,
		//			refreshToken: login.refreshToken,
		//			dPopKey: .init(alg: .es256, keyData: dpopKey.rawRepresentation),
		//			scopes: login.scopes,
		//			issuingServer: login.issuingServer,
		//			additionalParams: login.additionalParams
		//		).archive
	}

	private func getAuthorizationUrl(didDoc: DIDDocument) async throws -> URL {
		guard let pdsHost = try didDoc.pdsUrl.host() else {
			throw OAuthClientError.missingUrlHost
		}

		let pdsMetadata = try await getProtectedResourceMetadata(host: pdsHost)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256")
			else {
				throw OAuthClientError.notImplemented
			}
		}

		guard
			let authorizationServerString = pdsMetadata.authorizationServers?.first,
			let authorizationServerUrl = URL(string: authorizationServerString)
		else {
			throw OAuthClientError.missingUrlHost
		}
		return authorizationServerUrl
	}

	private static func loginProvider(
		server: ServerMetadata, validator: @escaping TokenSubscriberValidator
	) -> LoginProvider {
		return { params, dpopKey in
			// decode the params in the redirectURL
			guard
				let redirectComponents = URLComponents(
					url: params.redirectURL, resolvingAgainstBaseURL: false)
			else {
				throw AuthenticatorError.missingTokenURL
			}

			guard
				let authCode = redirectComponents.queryItems?.first(where: {
					$0.name == "code"
				})?.value,
				let iss = redirectComponents.queryItems?.first(where: {
					$0.name == "iss"
				})?.value,
				let state = redirectComponents.queryItems?.first(where: {
					$0.name == "state"
				})?.value
			else {
				throw AuthenticatorError.missingAuthorizationCode
			}

			if state != params.stateToken {
				throw AuthenticatorError.stateTokenMismatch(
					state, params.stateToken)
			}

			if iss != server.issuer {
				throw AuthenticatorError.issuingServerMismatch(iss, server.issuer)
			}

			// and use them (plus just a little more) to construct the token request
			guard let tokenURL = URL(string: server.tokenEndpoint) else {
				throw AuthenticatorError.missingTokenURL
			}

			guard let verifier = params.pkceVerifier?.verifier else {
				throw AuthenticatorError.pkceRequired
			}

			let tokenRequest = ATProto.TokenRequest(
				code: authCode,
				code_verifier: verifier,
				redirect_uri: params.credentials.callbackURL.absoluteString,
				grant_type: "authorization_code",
				client_id: params.credentials.clientId
			)

			var request = URLRequest(url: tokenURL)

			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("application/json", forHTTPHeaderField: "Accept")
			request.httpBody = try JSONEncoder().encode(tokenRequest)

			let (data, response) = try await params.responseProvider(request)

			print("data:", String(decoding: data, as: UTF8.self))
			print("response:", response)

			if let tokenError = try? JSONDecoder().decode(
				ATProto.TokenError.self,
				from: data
			) {
				if tokenError.errorDescription == "Code challenge already used" {
					throw AuthenticatorError.codeChallengeAlreadyUsed
				}
				Self.logger.error(
					"Login error: \(tokenError.errorDescription, privacy: .public)"
				)
				throw AuthenticatorError.unrecognizedError(
					tokenError.errorDescription)
			}

			do {
				let tokenResponse = try JSONDecoder().decode(
					ATProto.TokenResponse.self, from: data)
				guard tokenResponse.token_type == "DPoP" else {
					throw AuthenticatorError.dpopTokenExpected(
						tokenResponse.token_type)
				}

				if try await validator(tokenResponse, server.issuer) == false {
					throw AuthenticatorError.tokenInvalid
				}

				return tokenResponse.login(for: iss, dpopKey: dpopKey)
			} catch {
				Self.logger.error(
					"Error decoding response: \(String(decoding: data, as: UTF8.self), privacy: .public)"
				)
				throw AuthenticatorError.unrecognizedError("Decoding response JSON")
			}
		}
	}

	typealias TokenSubscriberValidator =
		@Sendable (ATProto.TokenResponse, _ issuer: String) async throws -> Bool
}

enum ATProto {
	struct TokenRequest: Hashable, Sendable, Codable {
		public let code: String
		public let code_verifier: String
		public let redirect_uri: String
		public let grant_type: String
		public let client_id: String

		public init(
			code: String, code_verifier: String, redirect_uri: String,
			grant_type: String, client_id: String
		) {
			self.code = code
			self.code_verifier = code_verifier
			self.redirect_uri = redirect_uri
			self.grant_type = grant_type
			self.client_id = client_id
		}
	}

	struct TokenResponse: Hashable, Sendable, Codable {
		public let access_token: String
		public let refresh_token: String?
		public let sub: String
		public let scope: String
		public let token_type: String
		public let expires_in: Int

		public func login(for issuingServer: String, dpopKey: OAuth.DPoPKey) -> SessionState
		{
			.init(
				accessToken: Token(value: access_token, expiresIn: expires_in),
				refreshToken: refresh_token.map { Token(value: $0) },
				dPopKey: dpopKey,
				scopes: scope,
				issuingServer: issuingServer,
				additionalParams: ["did": sub]
			)
		}

		public var accessToken: String { access_token }
		public var refreshToken: String? { refresh_token }
		public var tokenType: String { token_type }
		public var expiresIn: Int { expires_in }
	}

	struct TokenError: Hashable, Sendable, Codable {
		let error: String
		let errorDescription: String

		enum CodingKeys: String, CodingKey {
			case error
			case errorDescription = "error_description"
		}
	}
}
