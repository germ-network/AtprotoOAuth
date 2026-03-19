import AtprotoTypes
import Foundation
import GermConvenience

public actor AtprotoAgentImpl {
	public nonisolated let repo: Atproto.DID
	public nonisolated let resolver: AtprotoResolver
	private var baseURL: URL?
	private let resourceFetcher: HTTPFetcher

	public init(
		for did: Atproto.DID,
		resourceFetcher: HTTPFetcher = URLSession.shared,
		resolver: AtprotoResolver,
		serviceURL: URL? = URL(string: "https://public.api.bsky.app")!
	) {
		self.repo = did
		self.resourceFetcher = resourceFetcher
		self.resolver = resolver
		self.baseURL = serviceURL
	}
}

extension AtprotoAgentImpl: AtprotoAgent {
	public nonisolated var allowsAuthedCalls: Bool { false }

	public func response(_ request: AtprotoAgentRequest) async throws
		-> GermConvenience.HTTPDataResponse
	{
		var requestURL = try baseURL.tryUnwrap.appending(path: request.relativePath)
		requestURL = requestURL.appending(queryItems: request.queryItems)
		let request = URLRequest.createRequest(
			url: requestURL,
			httpMethod: request.httpMethod
		)
		return try await resourceFetcher.data(for: request)
	}

	public func authResponse(_ request: AtprotoAgentRequest) async throws
		-> GermConvenience.HTTPDataResponse
	{
		throw AtprotoAgentError.authedCallsNotPermitted
	}
}
