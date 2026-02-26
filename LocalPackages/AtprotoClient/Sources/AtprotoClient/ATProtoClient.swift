import AtprotoTypes
import Foundation
import OAuth

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol ATProtoClientInterface: Sendable {
	func plcDirectoryQuery(_: ATProtoDID) async throws -> DIDDocument

	func loadProtectedResourceMetadata(
		host: String
	) async throws -> ProtectedResourceMetadata

	func loadAuthServerMetadata(
		host: String
	) async throws -> AuthServerMetadata

	func getRepository<Result: AtprotoRecord>(
		recordType: Result.Type,
		repo: AtIdentifier,
		recordKey: RecordKey,
		pdsUrl: URL,
		recordCID: CID?,
	) async throws -> Lexicon.Com.Atproto.Repo.GetRecordOutput<Result>?
}

public struct ATProtoClient {
	let responseProvider: HTTPURLResponseProvider

	public init(responseProvider: @escaping HTTPURLResponseProvider) {
		self.responseProvider = responseProvider
	}
}

extension ATProtoClient: ATProtoClientInterface {
}
