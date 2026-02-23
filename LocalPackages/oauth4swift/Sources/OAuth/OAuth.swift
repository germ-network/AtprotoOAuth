import Foundation

public enum OAuthError: Error {
	case missingScheme
	case missingHTTPMethod
	case missingUrl
	case notImplemented
}

extension OAuthError: LocalizedError {
	var localizedDescription: String? {
		switch self {
		case .missingScheme: "Missing scheme"
		case .missingHTTPMethod: "Missing HTTP method"
		case .missingUrl: "Missing URL"
		case .notImplemented: "Not implemented"
		}
	}
}
