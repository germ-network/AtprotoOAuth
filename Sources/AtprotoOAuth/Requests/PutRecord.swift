//
//  PutRecord.swift
//  ATProtoOAuth
//
//  Created by Anna Mistele on 6/2/25.
//  Created by Christopher Jr Riley on 2024-03-11.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience

extension ATProtoOAuthSession {
	/// Writes a record in the repository, which may replace a previous record.
	///
	/// - Note: According to the AT Protocol specifications: "Write a repository record, creating
	/// or updating it as needed. Requires auth, implemented by PDS."
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/putRecord.json
	public func put<Record: AtprotoRecord>(
		record: Record,
		repo: AtIdentifier,
		recordKey: Atproto.RecordKey,  // The record key of the collection.
		// Indicates whether the record should be validated. Optional.
		shouldValidate: Bool? = true,
	) async throws -> Lexicon.Com.Atproto.Repo.StrongReference {
		let requestURL = try await getPDSUrl().appending(
			path: "/xrpc/com.atproto.repo.putRecord")

		let requestBody = Lexicon.Com.Atproto.Repo.PutRecordRequestBody(
			repo: repo.wireFormat,
			rkey: recordKey,
			validate: shouldValidate,
			record: record
		)

		let request = Self.createRequest(
			requestURL,
			httpMethod: .post,
			contentTypeValue: "application/json"
		)

		throw OAuthClientError.notImplemented

		//		let response = try await makeAuthenticated(
		//			request: request,
		//			withEncodingBody: requestBody,
		//		)
		//
		//		return try JSONDecoder().decode(
		//			Lexicon.Com.Atproto.Repo.StrongReference.self,
		//			from: response)
	}

	//	private func makeAuthenticated(
	//		request: URLRequest,
	//		withEncodingBody body: (Encodable & Sendable)? = nil,
	//	) async throws -> Data {
	//		var urlRequest = request
	//		if let body = body {
	//			urlRequest.httpBody = try JSONEncoder().encode(body)
	//		}
	//		let (data, resp) = try await dpopResponse(for: request)
	//		try ATProtoAPIErrorHandling.validate(data: data, resp: resp)
	//		return data
	//	}
	//
	//
	//
	//	private func dpopResponse(for request: URLRequest) async throws -> (
	//		Data,
	//		URLResponse
	//	) {
	//		guard case .active(let session) = state else {
	//			throw OAuthSessionError.sessionInactive
	//		}
	//		guard let generator = config.tokenHandling.dpopJWTGenerator else {
	//			return try await urlLoader(request)
	//		}
	//
	//		guard let pkce = config.tokenHandling.pkce else {
	//			throw AuthenticatorError.pkceRequired
	//		}
	//
	//		let token = login?.accessToken.value
	//		let tokenHash = token.map { pkce.hashFunction($0) }
	//
	//		return
	//			try await DPoPSigner
	//			.response(
	//				for: request,
	//				token: token,
	//				tokenHash: tokenHash,
	//				issuingServer: login?.issuingServer,
	//				nonce: nil,
	//				provider: { try await Self.response(for: $0) },
	//				dPoPKey: dPoPKey
	//			)
	//
	//	}
	//
	//	//was on Dpopsigner, compare to DpopSigner.response
	//	private func response(
	//		isolation: isolated (any Actor),
	//		for request: URLRequest,
	//		using jwtGenerator: JWTGenerator,
	//		token: String?,
	//		tokenHash: String?,
	//		issuingServer: String?,
	//		provider: URLResponseProvider
	//	) async throws -> (Data, URLResponse) {
	//		var request = request
	//
	//		try await authenticateRequest(&request, isolation: isolation, using: jwtGenerator, token: token, tokenHash: tokenHash, issuer: issuingServer)
	//
	//		let (data, response) = try await provider(request)
	//
	//		let existingNonce = nonce
	//
	//		self.nonce = try nonceDecoder(data, response)
	//
	//		if nonce == existingNonce {
	//			return (data, response)
	//		}
	//
	//		print("DPoP nonce updated", existingNonce ?? "", nonce ?? "")
	//
	//		// repeat once, using newly-established nonce
	//		try await authenticateRequest(&request, isolation: isolation, using: jwtGenerator, token: token, tokenHash: tokenHash, issuer: issuingServer)
	//
	//		return try await provider(request)
	//	}
	//
	private static func createRequest(
		_ requestURL: URL,
		httpMethod: HTTPMethod,
		contentTypeValue: String? = "application/json"
	) -> URLRequest {
		var request = URLRequest(url: requestURL)
		request.httpMethod = httpMethod.rawValue
		if httpMethod == .post,
			let contentTypeValue
		{
			request.addValue(contentTypeValue, forHTTPHeaderField: "Content-Type")
		}
		return request
	}
}
