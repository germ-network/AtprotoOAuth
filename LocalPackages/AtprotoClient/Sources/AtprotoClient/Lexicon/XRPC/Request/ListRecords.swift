//
//  ListRecords.swift
//  AtprotoTypes
//
//  Created by Anna Mistele on 3/2/26.
//

import AtprotoTypes
import Foundation

/// https://docs.bsky.app/docs/api/com-atproto-repo-list-records
/// https://lexicon.garden/lexicon/did:plc:6msi3pj7krzih5qxqtryxlzw/com.atproto.repo.listRecords/docs
/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/listRecords.json
extension Lexicon.Com.Atproto.Repo {
	public static let listRecordsNSID: Atproto.NSID = "com.atproto.repo.listRecords"

	public enum ListRecords<Result: AtprotoRecord>: XRPCRequest {
		public struct Result: Sendable, Codable {
			public let cursor: String?
			public let records: [Record]

			public init(cursor: String?, records: [Record]) {
				self.cursor = cursor
				self.records = records
			}
		}
		public static var nsid: Atproto.NSID { listRecordsNSID }
		public static var acceptValue: String { "application/json" }

		public struct Parameters: QueryParameters {
			let repo: AtIdentifier
			// TODO: Enforce min/max (1-100)?
			let limit: Int?
			let cursor: String?
			let reverse: Bool?

			public init(
				repo: AtIdentifier,
				limit: Int?,
				cursor: String?,
				reverse: Bool?
			) {
				self.repo = repo
				self.limit = limit
				self.cursor = cursor
				self.reverse = reverse
			}

			public func asQueryItems() -> [URLQueryItem] {
				var base: [URLQueryItem] = [
					.init(name: "repo", value: repo.wireFormat),
					.init(name: "collection", value: Result.nsid),
				]
				if let limit {
					base.append(.init(name: "limit", value: limit.description))
				}
				if let cursor {
					base.append(.init(name: "cursor", value: cursor))
				}
				if let reverse {
					base.append(
						.init(name: "reverse", value: reverse.description))
				}
				return base
			}
		}

		/// From https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/listRecords.json
		/// Same as the GetRecord output, but they're defined separately, so I'll leave them separate
		public struct Record: Sendable, Codable {
			/// The URI of the record.
			public let uri: String

			/// The CID hash for the record.
			public let cid: String

			/// The value for the record. Codable for later conversion
			public let value: Result

			public init(uri: String, cid: String, value: Result) {
				self.uri = uri
				self.cid = cid
				self.value = value
			}
		}
	}
}

extension Lexicon.Com.Atproto.Repo.ListRecords.Result: Mockable {
	public static func mock() -> Self {
		.init(
			cursor: UUID().uuidString,
			records: [
				.init(
					uri: UUID().uuidString,
					cid: CID.mock().string,
					value: Result.mock()
				)
			]
		)
	}
}
