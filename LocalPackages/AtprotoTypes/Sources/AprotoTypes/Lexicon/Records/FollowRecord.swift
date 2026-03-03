//
//  FollowRecord.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 4/28/25.
//

import Foundation

extension Lexicon.App.Bsky.Graph {
	public struct Follow: Sendable, Decodable {
		/// The identifier of the lexicon.
		///
		/// - Warning: The value must not change.
		//is "id" in the lexicon but avoid conflict with Swift id
		public static let nsid: Atproto.NSID = "app.bsky.graph.follow"

		public let subject: String  // DID
		// Ignoring the createdAt field until we can easily decode
		// public let createdAt: Date

		// Ignore `via` field
	}
}

extension Lexicon.App.Bsky.Graph.Follow: AtprotoRecord {
	public static func mock() -> Lexicon.App.Bsky.Graph.Follow {
		.init(subject: Atproto.DID.mock().fullId)
	}
}
