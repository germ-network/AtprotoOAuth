//
//  PutRecord.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/27/26.
//

import Foundation

//https://docs.bsky.app/docs/api/com-atproto-repo-put-record
//https://lexicon.garden/lexicon/did:plc:6msi3pj7krzih5qxqtryxlzw/com.atproto.repo.putRecord
extension Lexicon.Com.Atproto.Repo {
	public enum PutRecord<Record: AtprotoRecord>: XRPCProcedure {
		public static var nsid: Atproto.NSID { "com.atproto.repo.putRecord" }
		public typealias Result = PutRecordResult

		public struct Parameters: Encodable, ProcedureParameters {
			let repo: AtIdentifier
			let collection: Atproto.NSID
			let rkey: Atproto.RecordKey
			let record: Record
			let validate: Bool?
			let swapCommit: CID?
			let swapRecord: CID?

			public func httpBody() throws -> Data {
				try JSONEncoder().encode(self)
			}
		}
	}

	public struct PutRecordResult: Decodable {
		public let uri: String
		public let cid: String
		//commit: CommitMeta
		public let validationStatus: String
	}
}

extension Lexicon.Com.Atproto.Repo.PutRecord.Result: Mockable {
	public static func mock() -> Lexicon.Com.Atproto.Repo.PutRecordResult {
		.init(uri: "example", cid: "example", validationStatus: "unknown")
	}
}
