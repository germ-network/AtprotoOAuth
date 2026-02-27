//
//  PutRecordRequestBody.swift
//  ATProtoTypes
//
//  Pulled in by Anna Mistele on 4/16/25.
//  Created by Christopher Jr Riley on 5/20/24.
//

import Foundation

extension Lexicon.Com.Atproto.Repo {

	/// A request body model for creating a record that replaces a previous record.
	///
	/// - Note: According to the AT Protocol specifications: "Write a repository record, creating
	/// or updating it as needed. Requires auth, implemented by PDS."
	///
	/// - SeeAlso: This is based on the [`com.atproto.repo.putRecord`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/putRecord.json
	public struct PutRecordRequestBody<Record: AtprotoRecord>: Sendable {

		/// The decentralized identifier (DID) or handle of the repository.
		///
		/// - Note: According to the AT Protocol specifications: "The handle or DID of the repo
		/// (aka, current account)."
		public let repo: String

		/// The NSID of the record.
		///
		/// - Note: According to the AT Protocol specifications: "The NSID of the
		/// record collection."
		private(set) var collection: String = Record.nsid

		/// The record key of the collection.
		///
		/// - Note: According to the AT Protocol specifications: "The Record Key."
		public let rkey: Atproto.RecordKey

		/// Indicates whether the record should be validated. Optional.
		///
		/// - Note: According to the AT Protocol specifications: "Can be set to 'false' to skip
		/// Lexicon schema validation of record data, 'true' to require it, or leave unset to
		/// validate only for known Lexicons."
		public let validate: Bool?

		/// The record itself.
		///
		/// - Note: According to the AT Protocol specifications: "The record to write."
		public let record: Record

		public init(
			repo: String,
			rkey: Atproto.RecordKey,
			validate: Bool?,
			record: Record
		) {
			self.repo = repo
			self.rkey = rkey
			self.validate = validate
			self.record = record
		}
	}

	/// A output model for creating a record that replaces a previous record.
	///
	/// - Note: According to the AT Protocol specifications: "Write a repository record, creating
	/// or updating it as needed. Requires auth, implemented by PDS."
	///
	/// - SeeAlso: This is based on the [`com.atproto.repo.putRecord`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/putRecord.json
	public struct PutRecordOutput: Sendable, Codable {

		/// The URI of the record.
		public let uri: String

		/// The CID of the record.
		public let cid: String

		/// The status of the write operation's validation.
		public let validationStatus: ValidationStatus?

		/// The status of the write operation's validation.
		public enum ValidationStatus: String, Sendable, Codable {

			/// Status is valid.
			case valid

			/// Status is unknown.
			case unknown
		}
	}
}

extension Lexicon.Com.Atproto.Repo.PutRecordRequestBody: Codable {}
