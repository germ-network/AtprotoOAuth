import AtprotoTypes
import Foundation
import GermConvenience
import OAuth

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol ATProtoClientInterface: Sendable {
	func plcDirectoryQuery(_: Atproto.DID) async throws -> DIDDocument

	func loadProtectedResourceMetadata(
		host: String
	) async throws -> ProtectedResourceMetadata

	func loadAuthServerMetadata(
		host: String
	) async throws -> AuthServerMetadata

	func getRepository<Result: AtprotoRecord>(
		recordType: Result.Type,
		pdsUrl: URL,
		repo: AtIdentifier,
		recordKey: Atproto.RecordKey,
		recordCID: CID?,
	) async throws -> Lexicon.Com.Atproto.Repo.GetRecordOutput<Result>?

	func authRequest<X: XRPCInterface>(
		for xrpc: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
		session: AtprotoSession
	) async throws -> X.Result
}

public protocol AtprotoSession {
	func authResponse(
		for request: URLRequest,
	) async throws -> HTTPDataResponse
}

public struct ATProtoClient {
	let responseProvider: HTTPDataResponse.Responder

	public init(responseProvider: @escaping HTTPDataResponse.Responder) {
		self.responseProvider = responseProvider
	}
}

extension ATProtoClient: ATProtoClientInterface {
}
