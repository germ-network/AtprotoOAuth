//
//  Runtime+Interface.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import AuthenticationServices
import Crypto
import Foundation
import OAuth

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
		let didDoc = try await atprotoClient.plcDirectoryQuery(did)
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

		let parConfig = PARConfiguration(
			url: URL(string: serverConfig.pushedAuthorizationRequestEndpoint)!,
			parameters: ["login_hint": identity.serverHint]
		)

		return
			try await ATProtoOAuthSession
			.new(
				did: did,
				appCredentials: appCredentials,
				atprotoClient: atprotoClient
			)
			.performUserAuthentication(
				appCredentials: appCredentials,
				parConfig: parConfig,
				authEndpoint: serverConfig.authorizationEndpoint,
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
		server: AuthServerMetadata, validator: @escaping TokenSubscriberValidator
	) -> LoginProvider {
		{
			params,
			dpopKey in
			// decode the params in the redirectURL
			guard
				let redirectComponents = URLComponents(
					url: params.redirectURL, resolvingAgainstBaseURL: false)
			else {
				throw OAuthClientError.missingTokenURL
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
				throw OAuthClientError.missingAuthorizationCode
			}

			if state != params.stateToken {
				throw OAuthClientError.stateTokenMismatch(
					state, params.stateToken)
			}

			if iss != server.issuer {
				throw OAuthClientError.issuingServerMismatch(iss, server.issuer)
			}

			// and use them (plus just a little more) to construct the token request
			guard let tokenURL = URL(string: server.tokenEndpoint) else {
				throw OAuthClientError.missingTokenURL
			}

			guard let verifier = params.pkceVerifier?.verifier else {
				throw OAuthClientError.pkceRequired
			}

			let tokenRequest = ATProto.TokenRequest(
				code: authCode,
				codeVerifier: verifier,
				redirectUri: params.credentials.callbackURL.absoluteString,
				grantType: "authorization_code",
				clientId: params.credentials.clientId
			)

			var request = URLRequest(url: tokenURL)

			request.httpMethod = "POST"
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue("application/json", forHTTPHeaderField: "Accept")
			request.httpBody = try JSONEncoder().encode(tokenRequest)

			let result = try await params.responseProvider(request)
				.successErrorDecode(
					resultType: ATProto.TokenResponse.self,
					errorType: ATProto.TokenError.self,
				)

			switch result {
			case .result(let tokenResponse):
				guard tokenResponse.tokenType == "DPoP" else {
					throw OAuthClientError.dpopTokenExpected(
						tokenResponse.tokenType)
				}

				if try await validator(tokenResponse, server.issuer) == false {
					throw OAuthClientError.tokenInvalid
				}

				return tokenResponse.login(for: iss, dpopKey: dpopKey)
			case .error(let tokenError, let int):
				if tokenError.errorDescription == "Code challenge already used" {
					throw OAuthClientError.codeChallengeAlreadyUsed
				}
				Self.logger.error(
					"Login error: \(tokenError.errorDescription, privacy: .public)"
				)
				throw OAuthClientError.remoteTokenError(tokenError)
			}
		}
	}

	typealias TokenSubscriberValidator =
		@Sendable (ATProto.TokenResponse, _ issuer: String) async throws -> Bool
}

enum ATProto {
	struct TokenRequest: Hashable, Sendable, Codable {
		public let code: String
		public let codeVerifier: String
		public let redirectUri: String
		public let grantType: String
		public let clientId: String

		public init(
			code: String,
			codeVerifier: String,
			redirectUri: String,
			grantType: String,
			clientId: String
		) {
			self.code = code
			self.codeVerifier = codeVerifier
			self.redirectUri = redirectUri
			self.grantType = grantType
			self.clientId = clientId
		}

		public enum CodingKeys: String, CodingKey {
			case code
			case codeVerifier = "code_verifier"
			case redirectUri = "redirect_uri"
			case grantType = "grant_type"
			case clientId = "client_id"
		}
	}

	struct TokenResponse: Hashable, Sendable, Codable {
		public let accessToken: String
		public let refreshToken: String?
		public let sub: String
		public let scope: String
		public let tokenType: String
		public let expiresIn: Int

		public func login(for issuingServer: String, dpopKey: OAuth.DPoPKey) -> SessionState
		{
			.init(
				dPopKey: dpopKey,
				additionalParams: ["did": sub],
				mutable: .init(
					accessToken: .init(
						value: accessToken, expiresIn: expiresIn),
					refreshToken: refreshToken.map { .init(value: $0) },
					scopes: scope,
					issuingServer: issuingServer,
				)
			)
		}
		enum CodingKeys: String, CodingKey {
			case accessToken = "access_token"
			case refreshToken = "refresh_token"
			case sub
			case scope
			case tokenType = "token_type"
			case expiresIn = "expires_in"

		}
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
