//
//  Blob.swift
//  AtprotoTypes
//
//  Pulled in by Anna Mistele on 3/3/26.
//  Created by Christopher Jr Riley on 5/20/24.
//

extension Atproto {
	/// https://atproto.com/specs/blob
	public struct Blob: Sendable, Codable {

		/// Type of the blob.
		public let type: String?

		/// The strong reference of the blob.
		public let ref: Atproto.Blob.Reference

		/// The the MIME type.
		///
		/// This can be a `.jpg`, `.png`, and `.gif`.
		public let mimeType: String

		/// The size of the blob.
		public let size: Int

		enum CodingKeys: String, CodingKey {
			case type = "$type"
			case ref
			case mimeType
			case size
		}

		/// A data model for a blob reference definition.
		public struct Reference: Sendable, Codable, Equatable, Hashable {

			/// The link of the blob reference.
			public let link: String

			enum CodingKeys: String, CodingKey {
				case link = "$link"
			}
		}
	}
}
