import Foundation

public enum OAuthError: Error {
	case missingScheme
	case missingHTTPMethod
	case missingUrl
	case httpResponse(response: HTTPURLResponse)
	case notImplemented
}

extension OAuthError: LocalizedError {
	var localizedDescription: String? {
		switch self {
		case .missingScheme: "Missing scheme"
		case .missingHTTPMethod: "Missing HTTP method"
		case .missingUrl: "Missing URL"
		case .httpResponse(let response):
			"HTTP error with status code: \(response.statusCode), response: \(response)"
		case .notImplemented: "Not implemented"
		}
	}
}
