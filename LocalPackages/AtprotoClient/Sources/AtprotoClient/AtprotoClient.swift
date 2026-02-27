import AtprotoTypes
import Foundation
import GermConvenience

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol AtprotoClientInterface: Sendable {
	func plcDirectoryQuery(_: Atproto.DID) async throws -> DIDDocument

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
	func authResponse(for request: URLRequest) async throws -> HTTPDataResponse
}

public struct AtprotoClient {
	let responseProvider: HTTPDataResponse.Requester

	public init(responseProvider: @escaping HTTPDataResponse.Requester) {
		self.responseProvider = responseProvider
	}
}

extension AtprotoClient: AtprotoClientInterface {
}
