//
//  PreSession.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/26/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import Logging
import OAuth

//a container for a nonce cache for getting authorization
//it should only make requests as necessary to authorize

actor PreSession {
	static let logger = Logger(label: "PreSession")

	let appCredentials: AppCredentials

	let stateToken = UUID().uuidString
	let dpopKey = DPoPKey.generateP256()
	private let nonceCache: NSCache<NSString, NonceValue> = NSCache()
	let pkceVerifier = PKCEVerifier()

	init(appCredentials: AppCredentials) {
		self.appCredentials = appCredentials
	}
}

extension PreSession: DPoPNonceHolding {
	func response(request: URLRequest) async throws -> HTTPDataResponse {
		try await URLSession.defaultProvider(request)
	}

	public func getNonce(origin: String) -> NonceValue? {
		nonceCache.object(forKey: origin as NSString)
	}

	public func store(nonce: String, for origin: String) {
		nonceCache.setObject(
			.init(origin: origin, nonce: nonce),
			forKey: origin as NSString
		)
	}

	public static func decode(
		dataResponse: HTTPDataResponse
	) throws -> OAuth.NonceValue? {
		try AtprotoOAuthSessionImpl.decode(dataResponse: dataResponse)
	}
}

extension PreSession: PreSessionInterface {
	public static func authorizationURL(
		authEndpoint: String,
		parRequestURI: String,
		clientId: String,
	) throws -> URL {
		var components = URLComponents(string: authEndpoint)

		components?.queryItems = [
			URLQueryItem(name: "request_uri", value: parRequestURI),
			URLQueryItem(name: "client_id", value: clientId),
		]

		guard let url = components?.url else {
			throw OAuthSessionError.cantFormURL
		}

		return url
	}

	static func login(
		authorizationUrl: URL,
		stateToken: String,
		redirectURI: URL,
		pkceVerifier: PKCEVerifier,
		appCredentials: AppCredentials,
		authServerMetadata: AuthServerMetadata,
		dpopKey: DPoPKey,
		dpopRequester: (URLRequest) async throws -> HTTPDataResponse
	) async throws -> SessionState.Archive {
		// decode the params in the redirectURL

		let redirectComponents = try URLComponents(
			url: redirectURI,
			resolvingAgainstBaseURL: false
		).tryUnwrap(OAuthClientError.missingTokenURL)

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

		if state != stateToken {
			throw OAuthClientError.stateTokenMismatch(state, stateToken)
		}

		if iss != authServerMetadata.issuer {
			throw
				OAuthClientError
				.issuingServerMismatch(iss, authServerMetadata.issuer)
		}

		// and use them (plus just a little more) to construct the token request
		let tokenURL = try URL(string: authServerMetadata.tokenEndpoint)
			.tryUnwrap(OAuthClientError.missingTokenURL)

		let tokenRequest = Atproto.TokenRequest(
			code: authCode,
			codeVerifier: pkceVerifier.verifier,
			redirectUri: appCredentials.callbackURL.absoluteString,
			grantType: "authorization_code",
			clientId: appCredentials.clientId
		)

		var request = URLRequest(url: tokenURL)

		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.httpBody = try JSONEncoder().encode(tokenRequest)

		let result = try await dpopRequester(request)
			.successErrorDecode(
				resultType: Atproto.TokenResponse.self,
				errorType: Atproto.TokenError.self,
			)

		switch result {
		case .result(let tokenResponse):
			guard tokenResponse.tokenType == "DPoP" else {
				throw OAuthClientError.dpopTokenExpected(
					tokenResponse.tokenType)
			}

			try await Self.tokenSubscriberValidator(
				response: tokenResponse,
				sub: authServerMetadata.issuer
			)

			return tokenResponse.session(for: iss, dpopKey: dpopKey)
		case .error(let tokenError, let int):
			if tokenError.errorDescription == "Code challenge already used" {
				throw OAuthClientError.codeChallengeAlreadyUsed
			}
			Self.logger.error(
				"Login error: \(tokenError.errorDescription)"
			)
			throw OAuthClientError.remoteTokenError(tokenError)
		}
	}

	static func tokenSubscriberValidator(
		response: Atproto.TokenResponse,
		sub: String
	) async throws {
		// TODO: GER-1343 - Implement validator
		// after a token is issued, it is critical that the returned
		// identity be resolved and its PDS match the issuing server
		//
		// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
	}
}
