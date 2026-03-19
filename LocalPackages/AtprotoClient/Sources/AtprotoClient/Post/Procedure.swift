//
//  Procedure.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/5/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func authProcedure<X: XRPCProcedure>(
		_ xrpc: X.Type,
		parameters: X.Parameters,
	) async throws -> X.Result {
		let result = try await agent.authResponse(
			.init(
				relativePath: "/xrpc/" + X.nsid,
				queryItems: [],
				httpMethod: .post,
				httpBody: parameters.httpBody(),
				contentTypeValue: X.contentTypeValue,
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
