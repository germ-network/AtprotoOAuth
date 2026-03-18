import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience

extension Microcosm.Slingshot {
	/// - Parameter service: URL?
	/// - Returns: (serviceUrl: URL, proxy: String?)
	private func getServiceUrl(service: URL?) throws -> (URL, String?) {
		let defaultService = try Microcosm.Slingshot.defaultServiceURL.tryUnwrap

		guard let service else {
			// Using the default service:
			return (defaultService, nil)
		}

		// Using service proxying:
		guard let url = URL(string: "/", relativeTo: service) else {
			throw Microcosm.Errors.improperServiceUrl
		}

		guard let proxyHost = defaultService.host(percentEncoded: true) else {
			throw Microcosm.Errors.improperServiceUrl
		}

		return (url, "did:web:\(proxyHost)#slingshot")
	}

	public func request<X: XRPCRequest>(
		_ xrpc: X.Type,
		parameters: X.Parameters,
		service: URL?,
	) async throws -> X.Result {
		let (serviceUrl, proxy) = try getServiceUrl(service: service)
		var requestURL = serviceUrl.appending(path: "/xrpc/" + X.nsid)
		requestURL = requestURL.appending(queryItems: parameters.asQueryItems())

		var request = URLRequest.createRequest(
			url: requestURL,
			httpMethod: .get
		)

		if let proxy {
			request.setValue(
				proxy, forHTTPHeaderField: "atproto-proxy"
			)
		}

		let result = try await resourceFetcher.data(for: request)
			.success(
				decodeResult: X.Result.self,
				orError: Lexicon.XRPCError.self
			)

		switch result {
		case .error(let errorStruct, let statusCode):
			throw Microcosm.Errors.requestFailed(
				responseCode: statusCode,
				error: errorStruct.error
			)
		case .result(let result):
			return result
		}
	}
}
