//
//  URLSession+HTTPRequester.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/1/26.
//

import Foundation
import GermConvenience

enum URLSessionError: Error {
	case nonHttpResponse
}

extension URLSession {
	/// Convert a `URLSession` instance into a `URLResponseProvider`.
	public var responseProvider: HTTPDataResponse.Requester {
		{ request in
			let (data, urlResponse) = try await self.data(for: request)
			if let httpResponse = urlResponse as? HTTPURLResponse {
				return .init(data: data, response: httpResponse)
			} else {
				throw URLSessionError.nonHttpResponse
			}
		}
	}

	/// Convert a `URLSession` with a default configuration into a `URLResponseProvider`.
	public static var defaultProvider: HTTPDataResponse.Requester {
		URLSession(configuration: .default).responseProvider
	}

	public static var manualRefreshFetcher: HTTPDataResponse.Requester {
		URLSession(
			configuration: .default,
			delegate: ManualRedirect(),
			delegateQueue: nil
		)
		.responseProvider
	}
}

final class ManualRedirect: NSObject, URLSessionTaskDelegate {
	func urlSession(
		_ session: URLSession,
		task: URLSessionTask,
		willPerformHTTPRedirection response: HTTPURLResponse,
		newRequest request: URLRequest
	) async -> URLRequest? {
		nil
	}
}
