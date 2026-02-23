//
//  SessionProtocol.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Foundation

public protocol OAuthSession {
	static func response(for: URLRequest) async throws -> (Data, HTTPURLResponse)
	static func authorizationURLProvider(
		authEndpoint: String,
		params: AuthorizationURLParameters
	) throws -> URL
	//	static func userAuthenticate(url: URL, string: String) async throws -> URL
}

extension OAuthSession {
	static public func performUserAuthentication(
		appCredentials: AppCredentials,
		parConfig: PARConfiguration,
		authEndpoint: String,
		//		authorizationURLProvider: AuthorizationURLProvider,
		loginProvider: LoginProvider,
		userAuthenticator: @Sendable (URL, String) async throws -> URL
	) async throws -> SessionState.Archive {
		let stateToken = UUID().uuidString
		let dpopKey = DPoPKey.generateP256()

		let parRequestURI = try await getPARRequestURI(
			appCredentials: appCredentials,
			parConfig: parConfig,
			stateToken: stateToken,
			dPoPKey: dpopKey
		)

		let authConfig = AuthorizationURLParameters(
			credentials: appCredentials,
			parRequestURI: parRequestURI,
			stateToken: stateToken,
			responseProvider: {
				try await dpopResponse(for: $0, login: nil, dPoPKey: dpopKey)
			}
		)

		let tokenURL = try await Self.authorizationURLProvider(
			authEndpoint: authEndpoint,
			params: authConfig
		)

		let scheme = try appCredentials.callbackURLScheme

		let callbackURL = try await userAuthenticator(tokenURL, scheme)

		let params = LoginProviderParameters(
			authorizationURL: tokenURL,
			credentials: appCredentials,
			redirectURL: callbackURL,
			responseProvider: {
				try await Self.dpopResponse(
					for: $0,
					login: nil,
					dPoPKey: dpopKey
				)
			},
			stateToken: stateToken,
			pcke: PKCEVerifier()
		)

		return try await loginProvider(params, dpopKey).archive
	}

	private static func getPARRequestURI(
		appCredentials: AppCredentials,
		parConfig: PARConfiguration,
		stateToken: String,
		dPoPKey: DPoPKey
	) async throws -> String {
		try await parRequest(
			appCredentials: appCredentials,
			url: parConfig.url,
			params: parConfig.parameters,
			stateToken: stateToken,
			dPoPKey: dPoPKey
		).requestURI
	}

	private static func parRequest(
		appCredentials: AppCredentials,
		url: URL,
		params: [String: String],
		stateToken: String,
		dPoPKey: DPoPKey
	) async throws -> PARResponse {
		let pkceVerifier = PKCEVerifier()

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
			dPoPKey: dPoPKey
		)
		print(String(data: parData, encoding: .utf8))

		return try JSONDecoder().decode(PARResponse.self, from: parData)
	}

	private static func dpopResponse(
		for request: URLRequest,
		login: SessionStateShim?,
		dPoPKey: DPoPKey
	) async throws -> (Data, URLResponse) {

		let token = login?.accessToken.value
		let tokenHash = token.map { PKCEVerifier().hashFunction($0) }

		return
			try await DPoPSigner
			.response(
				for: request,
				token: token,
				tokenHash: tokenHash,
				issuingServer: login?.issuingServer,
				nonce: nil,
				provider: { try await Self.response(for: $0) },
				dPoPKey: dPoPKey
			)
	}
}

//to deprecate and depend on the session protocol

/// Function that can execute a `URLRequest`.
///
/// This is used to abstract the actual networking system from the underlying authentication
/// mechanism.
public typealias URLResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
