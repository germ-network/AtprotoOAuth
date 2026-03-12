import AtprotoTypes
import Foundation
import GermConvenience

extension Slingshot {
	/// - Parameter service: URL?
	/// - Returns: (serviceUrl: URL, proxy: String?)
	private func getServiceUrl(service: URL?) throws -> (URL, String?) {
		// Using service proxying:
		if let service = service {
			guard let url = URL(string: "/", relativeTo: service) else {
				throw SlingshotError.improperServiceUrl
			}

			guard let proxyHost = Slingshot.defaultServiceURL.host(percentEncoded: true)
			else {
				throw SlingshotError.improperServiceUrl
			}

			return (url, "did:web:\(proxyHost)#slingshot")
		} else {
			// Using the default service:
			return (Slingshot.defaultServiceURL, nil)
		}
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

		if let proxy = proxy {
			request.setValue(
				proxy, forHTTPHeaderField: "atproto-proxy"
			)
		}

		let result = try await responseProvider(request)
			.successErrorDecode(
				resultType: X.Result.self,
				errorType: Lexicon.XRPCError.self
			)

		switch result {
		case .error(let errorStruct, let statusCode):
			throw SlingshotError.requestFailed(
				responseCode: statusCode,
				error: errorStruct.error
			)
		case .result(let result):
			return result
		}
	}
}
