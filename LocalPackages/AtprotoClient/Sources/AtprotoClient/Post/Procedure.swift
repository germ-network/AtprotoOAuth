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
		pdsUrl: URL,
		parameters: X.Parameters,
		session: AtprotoSession
	) async throws -> X.Result {
		let requestURL = pdsUrl.appending(path: "/xrpc/" + X.nsid)

		let request = URLRequest.createRequest(
			url: requestURL,
			httpMethod: .post,
			httpBody: try parameters.httpBody(),
			contentTypeValue: "application/json"
		)

		let result = try await session.authResponse(for: request)
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
