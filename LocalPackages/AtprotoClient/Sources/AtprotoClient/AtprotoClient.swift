import AtprotoTypes
import Foundation
import GermConvenience

public struct AtprotoClient: Sendable {
	public let agent: AtprotoAgent

	public init(agent: AtprotoAgent) {
		self.agent = agent
	}
}

extension AtprotoClient {
	public func getRecord<R: AtprotoRecord>(
		parameters: Lexicon.Com.Atproto.Repo.GetRecord<R>.Parameters,
	) async throws -> R? {
		do {
			return try await request(
				Lexicon.Com.Atproto.Repo.GetRecord<R>.self,
				parameters: parameters,
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
		parameters: Lexicon.Com.Atproto.Repo.ListRecords<R>.Parameters,
	) async throws -> ([R], String?) {
		let result = try await request(
			Lexicon.Com.Atproto.Repo.ListRecords<R>.self,
			parameters: parameters,
		)
		let records = result.records.map { $0.value }
		return (records, result.cursor)
	}

	public func getBlob(
		parameters: Lexicon.Com.Atproto.Sync.GetBlob.Parameters,
	) async throws -> Data? {
		do {
			return try await request(
				Lexicon.Com.Atproto.Sync.GetBlob.self,
				parameters: parameters,
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
		parameters: Lexicon.Com.Atproto.Repo.PutRecord<R>.Parameters,
	) async throws {
		let _ = try await authProcedure(
			Lexicon.Com.Atproto.Repo.PutRecord<R>.self,
			parameters: parameters,
		)
	}
}
