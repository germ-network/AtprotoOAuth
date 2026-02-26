//
//  URLResponseProviderError.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation
import OAuth

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

enum URLResponseProviderError: Error {
	case missingResponseComponents
}

extension URLSession {
	/// Convert a `URLSession` instance into a `URLResponseProvider`.
	public var responseProvider: HTTPURLResponseProvider {
		{ request in
			let (data, urlResponse) = try await self.data(for: request)
			if let httpResponse = urlResponse as? HTTPURLResponse {
				return .init(data: data, response: httpResponse)
			} else {
				throw ATProtoClientError.nonHTTPResponse
			}
		}
	}

	/// Convert a `URLSession` with a default configuration into a `URLResponseProvider`.
	public static var defaultProvider: HTTPURLResponseProvider {
		URLSession(configuration: .default).responseProvider
	}
}
