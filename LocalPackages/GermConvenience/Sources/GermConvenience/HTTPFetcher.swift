//
//  HTTPFetcher.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 3/7/26.
//

import Foundation

#if canImport(FoundationNetworking)
	import FoundationNetworking
#endif

///We are not genericizing over the network stack as our HTTP request construction relies heavily on
///URLRequest which is tied closely to URLSession.
///This genericization serves to allow mock ingestion for testing
///This is a (sendable) object abstraction, not a closure, so that we can reason about the cache sharing
///which is localiized to an instance of a URLSession
public protocol HTTPFetcher: Sendable {
	func data(for: URLRequest) async throws -> HTTPDataResponse
}

///Authorization fetches should not follow redirects. This includes
///the protected resource metadata
///https://www.rfc-editor.org/rfc/rfc9728.html#section-3.2
///and auth server metadata
///https://datatracker.ietf.org/doc/html/rfc8414#section-3.2
extension URLSession {
	static public func manualRedirect() -> URLSession {
		URLSession(
			configuration: .default,
			delegate: ManualRedirect(),
			delegateQueue: nil
		)
	}
}

///The default (shared) urlsession does follow redirects, which is permitted for resource requests
extension URLSession: HTTPFetcher {
	public func data(for request: URLRequest) async throws -> HTTPDataResponse {
		let (data, urlResponse) = try await self.data(for: request)
		if let httpResponse = urlResponse as? HTTPURLResponse {
			return .init(data: data, response: httpResponse)
		} else {
			throw URLSessionError.nonHttpResponse
		}
	}
}

enum URLSessionError: Error {
	case nonHttpResponse
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
