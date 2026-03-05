//
//  DPoPResponse.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/26/26.
//

import Crypto
import Foundation
import GermConvenience

public protocol DPoPSigning: Actor {
	var dpopKey: DPoPKey { get throws }

	func getNonce(origin: String) -> IndexedNonce?
	func cacheNonce(response: HTTPDataResponse, requestUrl: URL) throws
}

extension DPoPSigning {
	func addProof(
		request: URLRequest,
		issuerOrigin: String?,
		token: String?
	) throws -> URLRequest {
		let requestOrigin = try (request.url?.origin)
			.tryUnwrap(DPoPError.requestInvalid(request))

		let nonce = getNonce(origin: requestOrigin)

		//right now the RFC has SHA256 baked into the RFC and a new draft needed
		//to specify alg agility
		let tokenHash = token.map {
			SHA256.hash(data: $0.utf8Data)
				.data.base64URLEncodedString()
		}
		let jwt = try dpopKey.sign(
			payload: .init(
				endpointUrl: request.url.tryUnwrap,
				httpMethod: request.httpMethod.tryUnwrap(
					OAuthError.missingHTTPMethod),
				nonce: nonce?.nonce,
				issuingServer: issuerOrigin,
				accessTokenHash: tokenHash
			)
		)

		var output = request
		output.setValue(jwt.string, forHTTPHeaderField: "DPoP")

		return output
	}
}

public protocol DPoPNonceHolding: Actor {
	var dpopKey: DPoPKey { get throws }

	func getNonce(origin: String) -> IndexedNonce?
	func store(indexedNonce: IndexedNonce)
	var httpRequester: HTTPDataResponse.Requester { get }

	//should return nil if nonce is not present and throw if it
	//incorrectly parses
	static func decode(
		dataResponse: HTTPDataResponse,
		requestUrl: URL  //if the response object is missing a URL, as fallback
	) throws -> IndexedNonce?
}

extension DPoPNonceHolding {
	//needs to be actor constrained so it can safely mutate the nonce cache
	//takes a base request, adds a dpop token, retrying if needed

	//this method is shared with the session object and the initial login
	func dpopResponse(
		for request: URLRequest,
		issuerOrigin: String?,
		token: String?,
	) async throws -> HTTPDataResponse {
		var request = request

		//right now the RFC has SHA256 baked into the RFC and a new draft needed
		//to specify alg agility
		let tokenHash = token.map {
			SHA256.hash(data: $0.utf8Data)
				.data.base64URLEncodedString()
		}

		// Requests must have a URL with an origin:
		let requestOrigin = try (request.url?.origin)
			.tryUnwrap(DPoPError.requestInvalid(request))

		let initNonce = getNonce(origin: requestOrigin)

		let method = try request.httpMethod.tryUnwrap(OAuthError.missingHTTPMethod)
		let requestUrl = try request.url.tryUnwrap(OAuthError.missingUrl)

		let jwt = try dpopKey.sign(
			payload: .init(
				endpointUrl: requestUrl,
				httpMethod: method,
				nonce: initNonce?.nonce,
				issuingServer: issuerOrigin,
				accessTokenHash: tokenHash
			)
		)

		request.setValue(jwt.string, forHTTPHeaderField: "DPoP")

		if let token {
			request.setValue("DPoP \(token)", forHTTPHeaderField: "Authorization")
		}

		let dataResponse = try await httpRequester(request)

		// Extract the next nonce value if any; if we don't have a new nonce, return the response:
		let nextNonce = try Self.decode(
			dataResponse: dataResponse,
			requestUrl: requestUrl
		)
		guard let nextNonce else {
			return dataResponse
		}

		// If the response doesn't have a new nonce, or the new nonce is the same as
		// the current nonce for the same origin, return the response:
		if nextNonce.origin == initNonce?.origin && nextNonce.nonce == initNonce?.nonce {
			return dataResponse
		}
		store(indexedNonce: nextNonce)

		//FIXME: revised logic
		let isAuthServer: Bool? = {
			if let issuerOrigin {
				issuerOrigin == requestOrigin
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
			payload: .init(
				endpointUrl: requestUrl,
				httpMethod: method,
				nonce: nextNonce.nonce,
				issuingServer: issuerOrigin,
				accessTokenHash: tokenHash
			)
		)
		request.setValue(secondJwt.string, forHTTPHeaderField: "DPoP")
		let retryDataResponse = try await httpRequester(request)

		let retryNonce = try Self.decode(
			dataResponse: retryDataResponse,
			requestUrl: requestUrl
		)
		if let retryNonce {
			store(indexedNonce: retryNonce)
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
