//
//  GetRecord.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/24/26.
//  Created by Christopher Jr Riley on 2024-05-20.
//

import Foundation

//https://docs.bsky.app/docs/api/com-atproto-repo-get-record
//https://lexicon.garden/lexicon/did:plc:6msi3pj7krzih5qxqtryxlzw/com.atproto.repo.getRecord/docs
/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/getRecord.json
extension Lexicon.Com.Atproto.Repo {
	public enum GetRecord<Result: AtprotoRecord>: XRPCRequest {
		public struct Result: Sendable, Codable {

			/// The URI of the record.
			public let uri: String

			/// The CID hash for the record.
			public let cid: String

			/// The value for the record. Codable for later conversion
			public let value: Result
		}
		public static var nsid: Atproto.NSID { "com.atproto.repo.getRecord" }

		public struct Parameters: QueryParameters {
			let repo: AtIdentifier
			let rkey: Atproto.RecordKey
			let cid: CID?

			public init(
				repo: AtIdentifier,
				rkey: Atproto.RecordKey,
				cid: CID?
			) {
				self.repo = repo
				self.rkey = rkey
				self.cid = cid
			}

			public func asQueryItems() -> [URLQueryItem] {
				var base: [URLQueryItem] = [
					.init(name: "repo", value: repo.wireFormat),
					.init(name: "collection", value: GetRecord.nsid),
					.init(name: "rkey", value: rkey),
				]
				if let cid {
					base.append(.init(name: "cid", value: cid.string))
				}

				return base
			}
		}
	}
}

extension Lexicon.Com.Atproto.Repo.GetRecord.Result: Mockable {
	public static func mock() -> Self {
		.init(
			uri: UUID().uuidString,
			cid: CID.mock().string,
			value: .mock()
		)
	}
}
