import AtprotoTypes
import Foundation
import GermConvenience

public struct AtprotoClient: Sendable {
	let responseProvider: HTTPDataResponse.Requester

	public init(responseProvider: @escaping HTTPDataResponse.Requester) {
		self.responseProvider = responseProvider
	}
}

extension AtprotoClient {
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

	func listRecords<R: AtprotoRecord>(
		pdsUrl: URL,
		parameters: Lexicon.Com.Atproto.Repo.ListRecords<R>.Parameters,
	) async throws -> ([R], String?) {
		let result = try await request(
			Lexicon.Com.Atproto.Repo.ListRecords<R>.self,
			pdsUrl: pdsUrl,
			parameters: parameters
		)
		let records = result.records.map { $0.value }
		return (records, result.cursor)
	}

	public func getBlob(
		pdsUrl: URL,
		parameters: Lexicon.Com.Atproto.Sync.GetBlob.Parameters,
	) async throws -> Data? {
		do {
			return try await request(
				Lexicon.Com.Atproto.Sync.GetBlob.self,
				pdsUrl: pdsUrl,
				parameters: parameters
			)
		} catch AtprotoClientError.requestFailed(400, let error) {
			if error == "BlobNotFound" {
				return nil
			} else {
				throw
					AtprotoClientError
					.requestFailed(responseCode: 400, error: error)
			}
		}
	}

	public func putRecord<R: AtprotoRecord>(
		did: Atproto.DID,
		parameters: Lexicon.Com.Atproto.Repo.PutRecord<R>.Parameters,
		session: AtprotoAgent
	) async throws {
		//rely on url caching for this value
		let pdsUrl = try await plcDirectoryQuery(did)
			.pdsUrl

		let _ = try await authProcedure(
			Lexicon.Com.Atproto.Repo.PutRecord<R>.self,
			pdsUrl: pdsUrl,
			parameters: parameters,
			session: session
		)
	}
}
