//
//  GetRecordOutput.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/24/26.
//  Created by Christopher Jr Riley on 2024-05-20.
//

import Foundation

extension Lexicon.Com.Atproto.Repo {

	/// An output model for a record.
	///
	/// - SeeAlso: This is based on the [`com.atproto.repo.getRecord`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/getRecord.json
	public struct GetRecordOutput<Result>: Sendable, Codable
	where Result: Codable, Result: Sendable {

		/// The URI of the record.
		public let uri: String

		/// The CID hash for the record.
		public let cid: String

		/// The value for the record. Codable for later conversion
		public let value: Result
	}

	public struct GetRecordError: Sendable, Codable {
		public let error: String
		let message: String
	}
}
