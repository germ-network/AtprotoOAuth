//
//  Authorize.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/8/26.
//

import Foundation
import GermConvenience

//for authorize
public struct AuthorizeInputs {
	let appCredentials: AppCredentials
	let stateToken: String
	let pkceVerifier: PKCEVerifier
	let parConfig: PARConfiguration?
	let issuer: URL

	public init(
		appCredentials: AppCredentials,
		stateToken: String = UUID().uuidString,
		pkceVerifier: PKCEVerifier = .init(),
		parConfig: PARConfiguration?,
		issuer: URL
	) {
		self.appCredentials = appCredentials
		self.stateToken = stateToken
		self.pkceVerifier = pkceVerifier
		self.parConfig = parConfig
		self.issuer = issuer
	}
}

//for authorize and refresh
public struct AuthComponents {
	let additionalParameters: [String: String]
	let authFetcher: HTTPFetcher
	let validator: (AuthServerMetadata, TokenEndpointResponse) throws -> SessionState.Mutable
	let dpopSigner: DPoPSigning?

	public init(
		additionalParameters: [String: String],
		authFetcher: HTTPFetcher,
		validator:
			@escaping (
				AuthServerMetadata,
				TokenEndpointResponse
			) throws -> SessionState.Mutable,
		dpopSigner: DPoPSigning?
	) {
		self.additionalParameters = additionalParameters
		self.authFetcher = authFetcher
		self.validator = validator
		self.dpopSigner = dpopSigner
	}

	public func performUserAuthentication(
		authorizeInputs: AuthorizeInputs,
		userAuthenticator: UserAuthenticator,
	) async throws -> SessionState.Archive {
		let clientId = authorizeInputs.appCredentials.clientId
		let challenge = authorizeInputs.pkceVerifier.challenge
		let scopes = authorizeInputs.appCredentials.requestedScopes.joined(separator: " ")
		let callbackURI = authorizeInputs.appCredentials.callbackURL

		let authServerMetadata = try await authFetcher.authServerDiscovery(
			issuer: authorizeInputs.issuer
		)

		if let parConfig = authorizeInputs.parConfig {
			let parParams = [
				"client_id": clientId,
				"state": authorizeInputs.stateToken,
				"scope": scopes,
				"response_type": "code",
				"redirect_uri": authorizeInputs.appCredentials.callbackURL
					.absoluteString,
				"code_challenge": challenge.value,
				"code_challenge_method": challenge.method,
			].merging(parConfig.parameters, uniquingKeysWith: { a, b in a })

			let parHTTPResponse = try await pushedAuthorizationRequest(
				authServerMetadata: authServerMetadata,
				appCredentials: authorizeInputs.appCredentials,
				params: parParams,
				headers: [:],
			)

			let parResponse = try OAuthComponents.processPushedAuthorizationResponse(
				response: parHTTPResponse
			)

			let tokenURL = try Self.authorizationURL(
				authEndpoint: authServerMetadata.authorizationEndpoint,
				parRequestURI: parResponse.requestURI,
				clientId: clientId
			)

			let scheme = try authorizeInputs.appCredentials.callbackURLScheme

			let callbackURL = try await userAuthenticator(tokenURL, scheme)

			return try await finishAuthorization(
				authorizationUrl: tokenURL,
				redirectURI: callbackURL,
				authInputs: authorizeInputs,
				authServerMetadata: authServerMetadata,
			)
		} else {
			throw OAuthError.notImplemented
		}
	}

	func pushedAuthorizationRequest(
		authServerMetadata: AuthServerMetadata,
		appCredentials: AppCredentials,
		params: [String: String],
		headers: [String: String],
	) async throws -> HTTPDataResponse {
		let parEndpoint = try authServerMetadata.resolve(
			endpoint: .par)

		var bodyParams = params
		bodyParams["client_id"] = appCredentials.clientId

		var headers = headers
		headers["accept"] = "application/json"
		headers["content-type"] = "application/x-www-form-urlencoded;charset=UTF-8"

		var request = URLRequest(url: parEndpoint)
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.httpMethod = HTTPMethod.post.rawValue
		request.httpBody = bodyParams.urlEncodedHTTPBody

		if let dpopSigner {
			return try await dpopSigner.nonceRetryAuthenticated(
				request: request,
				token: nil,
				authFetcher: authFetcher
			)
		} else {
			return try await authFetcher.data(for: request)
		}
	}

	static private func authorizationURL(
		authEndpoint: URL,
		parRequestURI: String,
		clientId: String,
	) throws -> URL {
		var components = URLComponents(url: authEndpoint, resolvingAgainstBaseURL: false)

		components?.queryItems = [
			URLQueryItem(name: "request_uri", value: parRequestURI),
			URLQueryItem(name: "client_id", value: clientId),
		]

		return try (components?.url).tryUnwrap
	}

	func finishAuthorization(
		authorizationUrl: URL,
		redirectURI: URL,
		authInputs: AuthorizeInputs,
		authServerMetadata: AuthServerMetadata,
	) async throws -> SessionState.Archive {
		let parsedRedirect = try OAuthComponents.validateAuthResponse(
			authServerMetadata: authServerMetadata,
			redirectURL: redirectURI,
			expectedState: authInputs.stateToken
		)

		let httpResponse = try await authorizationCodeGrantRequest(
			authServerMetadata: authServerMetadata,
			redirectUrl: authInputs.appCredentials.callbackURL,
			parsedRedirect: parsedRedirect,
			pkceVerifier: authInputs.pkceVerifier.verifier,
			additionalParameters: additionalParameters,
		)

		let result = try processAuthorizationCodeOAuth2Response(
			authServerMetadata: authServerMetadata,
			response: httpResponse
		)

		return .init(
			dPopKey: try dpopSigner?.dpopKey,
			additionalParams: nil,
			mutable: result
		)
	}

	public func authorizationCodeGrantRequest(
		authServerMetadata: AuthServerMetadata,
		redirectUrl: URL,
		parsedRedirect: OAuthComponents.ParsedRedirect,
		pkceVerifier: String?,
		additionalParameters: [String: String],
	) async throws -> HTTPDataResponse {
		var parameters = additionalParameters
		parameters["redirect_uri"] = redirectUrl.absoluteString
		parameters["code"] = parsedRedirect.authCode

		if let pkceVerifier {
			parameters["code_verifier"] = pkceVerifier
		}

		return try await tokenEndpointRequest(
			authServerMetadata: authServerMetadata,
			grantType: .authorizationCode,
			parameters: parameters,
			headers: [:],
		)
	}

	func processAuthorizationCodeOAuth2Response(
		authServerMetadata: AuthServerMetadata,
		response: HTTPDataResponse
	) throws -> SessionState.Mutable {
		let result = try OAuthComponents.processGenericAccessToken(response: response)

		//check the claims
		return try validator(authServerMetadata, result)
		// TODO: GER-1388 - Implement validator
		// after a token is issued, it is critical that the returned
		// identity be resolved and its PDS match the issuing server
		//
		// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
	}

	func tokenEndpointRequest(
		authServerMetadata: AuthServerMetadata,
		grantType: GrantType,
		parameters: [String: String],
		headers: [String: String],
	) async throws -> HTTPDataResponse {
		let url = try authServerMetadata.resolve(endpoint: .token)

		var modifiedParams = parameters
		modifiedParams["grant_type"] = grantType.rawValue

		var headers = headers
		headers["accept"] = "application/json"
		headers["content-type"] = "application/x-www-form-urlencoded;charset=UTF-8"

		var request = URLRequest(url: url)
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}

		request.httpMethod = HTTPMethod.post.rawValue
		let paramsString =
			try modifiedParams
			.map({ [$0, $1].joined(separator: "=") })
			.joined(separator: "&")
		request.httpBody = try modifiedParams.urlEncodedHTTPBody

		//review: confirm oauth4web doesn't retry "function tokenEndpointRequest"
		//for a nonce failure
		if let dpopSigner {
			return try await dpopSigner.authenticated(
				request: request,
				token: nil,
				authFetcher: authFetcher
			)
		} else {
			return try await authFetcher.data(for: request)
		}
	}
}

extension DPoPSigning {
	func nonceRetryAuthenticated(
		request: URLRequest,
		token: String?,
		authFetcher: HTTPFetcher
	) async throws -> HTTPDataResponse {
		let firstResponse = try await authenticated(
			request: request,
			token: token,
			authFetcher: authFetcher
		)

		//retry if nonceError
		if firstResponse.isDPoPNonceError {
			return try await authenticated(
				request: request,
				token: token,
				authFetcher: authFetcher
			)
		} else {
			return firstResponse
		}
	}

	//tries just once
	func authenticated(
		request: URLRequest,
		token: String?,
		authFetcher: HTTPFetcher
	) async throws -> HTTPDataResponse {
		let proofRequest = try addProof(
			request: request,
			token: nil,
		)

		let response = try await authFetcher.data(for: proofRequest)

		try cacheNonce(
			response: response,
			requestUrl: proofRequest.url.tryUnwrap
		)

		return response
	}
}

extension [String: String] {
	var urlEncodedHTTPBody: Data {
		map({ [$0, $1].joined(separator: "=") })
			.joined(separator: "&")
			.utf8Data
	}
}
