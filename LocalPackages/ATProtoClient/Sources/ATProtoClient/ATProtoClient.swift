import ATProtoTypes
import Foundation
import OAuthenticator

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol ATProtoClientInterface: Sendable {
	func resolveDocument(did: ATProtoDID) async throws -> DIDDocument

	func loadProtectedResourceMetadata(
		host: String
	) async throws -> ProtectedResourceMetadata
}

public struct ATProtoClient {
	let responseProvider: URLResponseProvider

	public init(responseProvider: @escaping URLResponseProvider) {
		self.responseProvider = responseProvider
	}
}
