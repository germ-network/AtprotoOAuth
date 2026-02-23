import ATProtoTypes
import Foundation
import OAuth
import OAuthenticator

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol ATProtoClientInterface: Sendable {
	func plcDirectoryQuery(_: ATProtoDID) async throws -> DIDDocument

	func loadProtectedResourceMetadata(
		host: String
	) async throws -> ProtectedResourceMetadata

	func loadAuthServerMetadata(
		host: String
	) async throws -> ServerMetadata
}

public struct ATProtoClient {
	let responseProvider: URLResponseProvider

	public init(responseProvider: @escaping URLResponseProvider) {
		self.responseProvider = responseProvider
	}
}

extension ATProtoClient: ATProtoClientInterface {
}
