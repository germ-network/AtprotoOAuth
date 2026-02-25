//
//  SessionProtocol.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Crypto
import Foundation

public protocol OAuthSession: Actor {
	static func response(for: URLRequest) async throws -> (Data, HTTPURLResponse)

	static func authorizationURLProvider(
		authEndpoint: String,
		parRequestURI: String,
		clientId: String,
	) throws -> URL

	func getNonce(origin: String) -> NonceValue?
	func store(nonce: String, for: String)
	func decode(nonceResult: Data, response: HTTPURLResponse) throws -> NonceValue?

	//	static func userAuthenticate(url: URL, string: String) async throws -> URL
}

extension OAuthSession {
	//call chain is static method so we can reuse it before we have a session
	public func performUserAuthentication(
		appCredentials: AppCredentials,
		parConfig: PARConfiguration,
		authEndpoint: String,
		loginProvider: LoginProvider,
		userAuthenticator: @Sendable (URL, String) async throws -> URL
	) async throws -> SessionState.Archive {
		let stateToken = UUID().uuidString
		let dpopKey = DPoPKey.generateP256()
		let pkceVerifier = PKCEVerifier()

		let parRequestURI = try await getPARRequestURI(
			appCredentials: appCredentials,
			parConfig: parConfig,
			stateToken: stateToken,
			dPoPKey: dpopKey,
			pkceVerifier: pkceVerifier
		)

		let tokenURL = try await Self.authorizationURLProvider(
			authEndpoint: authEndpoint,
			parRequestURI: parRequestURI,
			clientId: appCredentials.clientId
		)

		let scheme = try appCredentials.callbackURLScheme

		let callbackURL = try await userAuthenticator(tokenURL, scheme)

		let params = LoginProviderParameters(
			authorizationURL: tokenURL,
			credentials: appCredentials,
			redirectURL: callbackURL,
			responseProvider: {
				try await self.dpopResponse(
					for: $0,
					login: nil,
					dPoPKey: dpopKey,
					pkceVerifier: pkceVerifier
				)
			},
			stateToken: stateToken,
			pkceVerifier: pkceVerifier
		)

		return try await loginProvider(params, dpopKey).archive
	}

	private func getPARRequestURI(
		appCredentials: AppCredentials,
		parConfig: PARConfiguration,
		stateToken: String,
		dPoPKey: DPoPKey,
		pkceVerifier: PKCEVerifier
	) async throws -> String {
		try await parRequest(
			appCredentials: appCredentials,
			url: parConfig.url,
			params: parConfig.parameters,
			stateToken: stateToken,
			dPoPKey: dPoPKey,
			pkceVerifier: pkceVerifier
		).requestURI
	}

	private func parRequest(
		appCredentials: AppCredentials,
		url: URL,
		params: [String: String],
		stateToken: String,
		dPoPKey: DPoPKey,
		pkceVerifier: PKCEVerifier
	) async throws -> PARResponse {
		let challenge = pkceVerifier.challenge
		let scopes = appCredentials.scopes.joined(separator: " ")
		let callbackURI = appCredentials.callbackURL
		let clientId = appCredentials.clientId

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.setValue(
			"application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

		let base: [String: String] = [
			"client_id": clientId,
			"state": stateToken,
			"scope": scopes,
			"response_type": "code",
			"redirect_uri": callbackURI.absoluteString,
			"code_challenge": challenge.value,
			"code_challenge_method": challenge.method,
		]

		let body =
			params
			.merging(base, uniquingKeysWith: { a, b in a })
			.map({ [$0, $1].joined(separator: "=") })
			.joined(separator: "&")

		request.httpBody = Data(body.utf8)

		let (parData, response) = try await dpopResponse(
			for: request,
			login: nil,
			dPoPKey: dPoPKey,
			pkceVerifier: pkceVerifier
		)

		guard response.statusCode >= 200 && response.statusCode < 300 else {
			throw
				OAuthError
				.httpResponse(response: response)
		}

		return try JSONDecoder().decode(PARResponse.self, from: parData)
	}

	private func dpopResponse(
		for request: URLRequest,
		login: SessionState?,
		dPoPKey: DPoPKey,
		pkceVerifier: PKCEVerifier
	) async throws -> (Data, HTTPURLResponse) {
		try await response(
			for: request,
			token: login?.accessToken.value,
			issuingServer: login?.issuingServer,
			provider: { try await Self.response(for: $0) },
			dPoPKey: dPoPKey
		)
	}

	//needs to be actor constrained so it can safely mutate the nonce cahce
	public func response(
		for request: URLRequest,
		token: String?,
		issuingServer: String?,
		provider: HTTPURLResponseProvider,
		dPoPKey: DPoPKey,
	) async throws -> (Data, HTTPURLResponse) {
		var request = request
		var issuer: String? = nil
		if let iss = issuingServer {
			issuer = URL(string: iss)?.origin
		}

		let tokenHash = token.map {
			SHA256.hash(data: Data($0.utf8))
				.data.base64URLEncodedString()
		}

		// Requests must have a URL with an origin:
		guard let requestOrigin = request.url?.origin else {
			throw DPoPError.requestInvalid(request)
		}

		let initNonce = getNonce(origin: requestOrigin)

		guard let method = request.httpMethod else {
			throw OAuthError.missingHTTPMethod
		}
		guard let url = request.url else {
			throw OAuthError.missingUrl
		}

		let jwt = try await Self.generateJWT(
			method: method,
			requestUrl: url,
			nonce: initNonce?.nonce,
			tokenHash: tokenHash,
			issuer: issuingServer,
			dPoPKey: dPoPKey
		)
		request.setValue(jwt, forHTTPHeaderField: "DPoP")

		if let token {
			request.setValue("DPoP \(token)", forHTTPHeaderField: "Authorization")
		}

		let (data, response) = try await provider(request)

		// Extract the next nonce value if any; if we don't have a new nonce, return the response:
		guard
			let nextNonce = try decode(
				nonceResult: data,
				response: response
			)
		else {
			return (data, response)
		}

		// If the response doesn't have a new nonce, or the new nonce is the same as
		// the current nonce for the same origin, return the response:
		if nextNonce.origin == initNonce?.origin && nextNonce.nonce == initNonce?.nonce {
			return (data, response)
		}
		store(nonce: nextNonce.nonce, for: nextNonce.origin)

		//FIXME: revised logic
		let isAuthServer: Bool? = {
			if let issuer {
				issuer == requestOrigin
			} else {
				nil
			}
		}()

		//fixme: adopt logic from OAuthenticator pr 50
		let shouldRetry = Self.isUseDpopError(
			data: data, response: response, isAuthServer: isAuthServer)
		if !shouldRetry {
			return (data, response)
		}

		// repeat once, using newly-established nonce
		let secondJwt = try await Self.generateJWT(
			method: method,
			requestUrl: url,
			nonce: nextNonce.nonce,
			tokenHash: tokenHash,
			issuer: issuingServer,
			dPoPKey: dPoPKey
		)
		request.setValue(secondJwt, forHTTPHeaderField: "DPoP")
		let (retryData, retryResponse) = try await provider(request)

		if let retryNonce = try decode(
			nonceResult: retryData,
			response: retryResponse
		) {
			store(nonce: retryNonce.nonce, for: retryNonce.origin)
		}

		return (retryData, retryResponse)
	}

	private static func generateJWT(
		method: String,
		requestUrl: URL,
		nonce: String?,
		tokenHash: String?,
		issuer: String?,
		dPoPKey: DPoPKey,
	) throws -> String {
		try dPoPKey.sign(
			.init(
				keyType: "dpop+jwt",
				httpMethod: method,
				requestEndpoint: requestUrl.absoluteString,
				nonce: nonce,
				tokenHash: tokenHash,
				issuingServer: issuer
			)
		)
	}

	// The logic here is taken from:
	// https://github.com/bluesky-social/atproto/blob/4e96e2c7/packages/oauth/oauth-client/src/fetch-dpop.ts#L195
	private static func isUseDpopError(
		data: Data, response: HTTPURLResponse, isAuthServer: Bool?
	) -> Bool {
		// https://datatracker.ietf.org/doc/html/rfc6750#section-3
		// https://datatracker.ietf.org/doc/html/rfc9449#name-resource-server-provided-no

		switch (isAuthServer, response.statusCode) {
		case (let authServer, 401) where authServer != true:
			if let wwwAuthHeader = response.value(
				forHTTPHeaderField: "WWW-Authenticate")
			{
				if wwwAuthHeader.starts(with: "DPoP") {
					return wwwAuthHeader.contains("error=\"use_dpop_nonce\"")
				}
			}
		// https://datatracker.ietf.org/doc/html/rfc9449#name-authorization-server-provid
		case (let authServer, 400) where authServer != false:
			do {
				let err = try JSONDecoder().decode(
					OAuthErrorResponse.self, from: data)
				return err.error == "use_dpop_nonce"
			} catch {
				return false
			}
		default:
			return false
		}

		return false
	}
}

//to deprecate and depend on the session protocol

public typealias HTTPURLResponseProvider =
	@Sendable (URLRequest) async throws -> (
		Data,
		HTTPURLResponse
	)
