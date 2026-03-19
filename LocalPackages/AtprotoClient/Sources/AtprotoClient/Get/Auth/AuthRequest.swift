//
//  AuthRequest.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/26/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

extension AtprotoClient {
	public func authRequest<X: XRPCRequest>(
		_ xrpc: X.Type,
		parameters: X.Parameters
	) async throws -> X.Result {
		let result = try await agent.authResponse(
			.init(
				relativePath: "/xrpc/" + X.nsid,
				queryItems: parameters.asQueryItems(),
				httpMethod: .get,
				acceptValue: X.acceptValue
			)
		)
		.success(
			decodeResult: X.Result.self,
			orError: Lexicon.XRPCError.self
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
