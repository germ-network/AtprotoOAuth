//
//  AuthRequest.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/26/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func authRequest<X: XRPCInterface>(
		for xrpc: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
		session: AtprotoSession
	) async throws -> X.Result {
		var requestURL = pdsUrl.appending(path: "/xrpc/app.bsky.actor.getProfile")
		requestURL = requestURL.appending(queryItems: parameters.asQueryItems())
		let request = createRequest(url: requestURL, httpMethod: .get)

		let result = try await session.authResponse(for: request)
			.successErrorDecode(
				resultType: X.Result.self,
				errorType: Lexicon.XRPCError.self
			)

		switch result {
		case .error(let errorStruct, let statusCode):
			throw AtprotoClientError.requestFailed(
				responseCode: statusCode,
				error: errorStruct.error
			)
		case .result(let result):
			return result
		}
	}
}
