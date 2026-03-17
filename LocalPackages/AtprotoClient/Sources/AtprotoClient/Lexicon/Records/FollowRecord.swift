//
//  FollowRecord.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 4/28/25.
//

import AtprotoTypes
import Foundation

extension Lexicon.App.Bsky.Graph {
	public struct Follow: Sendable, Codable {
		/// The identifier of the lexicon.
		///
		/// - Warning: The value must not change.
		//is "id" in the lexicon but avoid conflict with Swift id
		public static let nsid: Atproto.NSID = "app.bsky.graph.follow"
		//for encoding
		private(set) var nsid: Atproto.NSID = Self.nsid

		public let subject: String  // DID
		// Ignoring the createdAt field until we can easily decode
		// public let createdAt: Date

		// Ignore `via` field

		enum CodingKeys: String, CodingKey {
			case nsid = "$type"
			case subject
		}
	}
}

extension Lexicon.App.Bsky.Graph.Follow: AtprotoRecord {
	public static func mock() -> Lexicon.App.Bsky.Graph.Follow {
		.init(subject: Atproto.DID.mock().stringRepresentation)
	}
}
