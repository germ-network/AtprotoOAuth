import AtprotoTypes
import Foundation
import GermConvenience

public actor AtprotoAgentImpl {
	public nonisolated let repo: Atproto.DID
	private var publicAPI = URL(string: "https://public.api.bsky.app")!
	private let resourceFetcher: HTTPFetcher

	public init(
		for repo: Atproto.DID,
		resourceFetcher: HTTPFetcher = URLSession.shared
	) {
		self.repo = repo
		self.resourceFetcher = resourceFetcher
	}
}

extension AtprotoAgentImpl: AtprotoAgent {
	public nonisolated var allowsAuthedCalls: Bool { false }
	
	public func response(_ request: AtprotoAgentRequest) async throws -> GermConvenience.HTTPDataResponse {
		var requestURL = publicAPI.appending(path: request.relativePath)
		requestURL = requestURL.appending(queryItems: request.queryItems)
		let request = URLRequest.createRequest(
			url: requestURL,
			httpMethod: request.httpMethod
		)
		return try await resourceFetcher.data(for: request)
	}
	
	public func authResponse(_ request: AtprotoAgentRequest) async throws -> GermConvenience.HTTPDataResponse {
		throw AtprotoAgentError.authedCallsNotPermitted
	}
}
