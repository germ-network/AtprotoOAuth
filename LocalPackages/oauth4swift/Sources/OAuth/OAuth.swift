import Foundation
import GermConvenience

enum OAuthError: Error {
	case missingScheme
	case missingHTTPMethod
	case missingUrl
	case missingDPoPKey
	case insecureScheme
	case unrecognizedTokenType
	case httpResponse(response: HTTPURLResponse)
	case notImplemented
}

extension OAuthError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .missingScheme: "Missing scheme"
		case .missingHTTPMethod: "Missing HTTP method"
		case .missingUrl: "Missing URL"
		case .missingDPoPKey: "Missing dPoP key"
		case .insecureScheme: "Insecure scheme"
		case .unrecognizedTokenType: "Unrecognized Token Type"
		case .httpResponse(let response):
			"HTTP error with status code: \(response.statusCode), response: \(response)"
		case .notImplemented: "Not implemented"
		}
	}
}

//Abstraction of ASWebAuthentication or AuthTabIntent
public typealias UserAuthenticator = @Sendable (URL, String) async throws -> URL

//parking place for oauth4web analogs
enum OAuth {
	static func processGenericAccessToken(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		let decoded: TokenEndpointResponse = try response.successDecode(successCode: 200)

		return decoded
	}

	struct TokenResponse: Decodable {
		let accessToken: String
		let tokenType: String
		let scope: String?
		let idToken: String?

		enum CodingKeys: String, CodingKey {
			case accessToken = "access_token"
			case tokenType = "token_type"
			case scope
			case idToken = "id_token"
		}
	}
}
