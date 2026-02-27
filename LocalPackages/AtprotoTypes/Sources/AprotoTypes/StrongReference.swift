//
//  StrongReference.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/24/26.
//

//
//  RepoStrongRef.swift
//  AtprotoLiteClient
//
//  Pulled in by Anna Mistele on 4/16/25.
//  Created by Christopher Jr Riley on 5/20/24.
//

import Foundation

extension Lexicon.Com.Atproto.Repo {

	/// A main data model definition for a strong reference.
	///
	/// - Note: According to the AT Protocol specifications: "A URI with a
	/// content-hash fingerprint."
	///
	/// - SeeAlso: This is based on the [`com.atproto.repo.strongRef`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/strongRef.json
	public struct StrongReference: Codable, Sendable {

		/// The URI for the record.
		public let uri: String

		/// The CID hash for the record.
		public let cid: String

		public init(uri: String, cid: String) {
			self.uri = uri
			self.cid = cid
		}
	}

	public struct CommitReference: Codable, Sendable {
		public let cid: String
		public let tid: String

		public init(cid: String, tid: String) {
			self.cid = cid
			self.tid = tid
		}
	}
}
