import AtprotoTypes
import Foundation
import GermConvenience

//abstract out the protocol so we can sub in a mock one for offline testing
public protocol AtprotoClientInterface: Sendable {
	func plcDirectoryQuery(_: Atproto.DID) async throws -> DIDDocument

	func authProcedure<X: XRPCProcedure>(
		_: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
		session: AtprotoSession
	) async throws -> X.Result

	func authRequest<X: XRPCRequest>(
		_: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
		session: AtprotoSession
	) async throws -> X.Result

	func request<X: XRPCRequest>(
		_: X.Type,
		pdsUrl: URL,
		parameters: X.Parameters,
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

extension AtprotoClientInterface {
	func getRecord<R: AtprotoRecord>(
		pdsUrl: URL,
		parameters: Lexicon.Com.Atproto.Repo.GetRecord<R>.Parameters,
	) async throws -> R? {
		do {
			return try await request(
				Lexicon.Com.Atproto.Repo.GetRecord<R>.self,
				pdsUrl: pdsUrl,
				parameters: parameters
			).value
			//this is per the api docs, not the lexicon
		} catch AtprotoClientError.requestFailed(400, let error) {
			if error == "RecordNotFound" {
				return nil
			} else {
				throw
					AtprotoClientError
					.requestFailed(responseCode: 400, error: error)
			}
		}
	}
}
