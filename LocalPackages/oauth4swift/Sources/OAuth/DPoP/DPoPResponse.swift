//
//  DPoPResponse.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/26/26.
//

import Crypto
import Foundation
import GermConvenience

public protocol DPoPNonceHolding: Actor {
	var dpopKey: DPoPKey { get throws }

	func getNonce(origin: String) -> NonceValue?
	func store(nonce: String, for: String)
	func response(request: URLRequest) async throws -> HTTPDataResponse

	static func decode(dataResponse: HTTPDataResponse) throws -> NonceValue?
}

extension DPoPNonceHolding {
	//needs to be actor constrained so it can safely mutate the nonce cache
	//takes a base request, adds a dpop token, retrying if needed

	//this method is shared with the session object and the initial login
	public func dpopResponse(
		for request: URLRequest,
		token: String?,
		issuingServer: String?,
	) async throws -> HTTPDataResponse {
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
		let requestOrigin = try (request.url?.origin)
			.tryUnwrap(DPoPError.requestInvalid(request))

		let initNonce = getNonce(origin: requestOrigin)

		let method = try request.httpMethod.tryUnwrap(OAuthError.missingHTTPMethod)

		let url = try request.url.tryUnwrap(OAuthError.missingUrl)

		let jwt = try dpopKey.sign(
			.init(
				keyType: "dpop+jwt",
				httpMethod: method,
				requestEndpoint: url.absoluteString,
				nonce: initNonce?.nonce,
				tokenHash: tokenHash,
				issuingServer: issuer
			)
		)

		request.setValue(jwt, forHTTPHeaderField: "DPoP")

		if let token {
			request.setValue("DPoP \(token)", forHTTPHeaderField: "Authorization")
		}

		let dataResponse = try await response(request: request)

		// Extract the next nonce value if any; if we don't have a new nonce, return the response:
		guard let nextNonce = try Self.decode(dataResponse: dataResponse) else {
			return dataResponse
		}

		// If the response doesn't have a new nonce, or the new nonce is the same as
		// the current nonce for the same origin, return the response:
		if nextNonce.origin == initNonce?.origin && nextNonce.nonce == initNonce?.nonce {
			return dataResponse
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
			dataResponse: dataResponse, isAuthServer: isAuthServer
		)
		if !shouldRetry {
			return dataResponse
		}

		// repeat once, using newly-established nonce
		let secondJwt = try dpopKey.sign(
			.init(
				keyType: "dpop+jwt",
				httpMethod: method,
				requestEndpoint: url.absoluteString,
				nonce: nextNonce.nonce,
				tokenHash: tokenHash,
				issuingServer: issuer
			)
		)
		request.setValue(secondJwt, forHTTPHeaderField: "DPoP")
		let retryDataResponse = try await response(request: request)

		if let retryNonce = try Self.decode(dataResponse: retryDataResponse) {
			store(nonce: retryNonce.nonce, for: retryNonce.origin)
		}

		return retryDataResponse
	}

	// The logic here is taken from:
	// https://github.com/bluesky-social/atproto/blob/4e96e2c7/packages/oauth/oauth-client/src/fetch-dpop.ts#L195
	private static func isUseDpopError(
		dataResponse: HTTPDataResponse, isAuthServer: Bool?
	) -> Bool {
		// https://datatracker.ietf.org/doc/html/rfc6750#section-3
		// https://datatracker.ietf.org/doc/html/rfc9449#name-resource-server-provided-no

		switch (isAuthServer, dataResponse.response.statusCode) {
		case (let authServer, 401) where authServer != true:
			if let wwwAuthHeader = dataResponse.response.value(
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
					OAuthErrorResponse.self, from: dataResponse.data)
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
