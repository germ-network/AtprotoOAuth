//
//  Request.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

extension AtprotoClient {
	public func request<X: XRPCRequest>(
		_ xrpc: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
	) async throws -> X.Result {
		var requestURL = pdsUrl.appending(path: "/xrpc/" + X.nsid)
		requestURL = requestURL.appending(queryItems: parameters.asQueryItems())
		let request = URLRequest.createRequest(
			url: requestURL,
			httpMethod: .get
		)

		let result = try await resourceFetcher.data(for: request)
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
