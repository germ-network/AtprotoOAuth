//
//  ProfileAuthedMetadata.swift
//  AtprotoTypes
//
//  Created by Anna Mistele on 9/24/25.
//

import Foundation

extension Lexicon.App.Bsky.Actor.Defs {

	/// A definition model for a profile view based on profileViewDetailed.
	///
	/// - SeeAlso: This is based on the [`app.bsky.actor.defs`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/actor/defs.json
	///TODO: match the lexicon def
	public struct ProfileViewDetailed: Sendable, Decodable {

		/// The decentralized identifier (DID) of the user.
		public let did: String
		public let handle: String
		public let displayName: String?
		public let pronouns: String?
		public let avatar: URL?

		/// The unique handle of the user.
		//		public let actorHandle: String

		/// The display name of the user's profile. Optional.
		///
		/// - Important: Current maximum length is 64 characters.
		//		public let displayName: String?

		/// The description of the user's profile. Optional.
		///
		/// - Important: Current maximum length is 256 characters.
		//		public let description: String?

		/// The avatar image URL of a user's profile. Optional.
		//		public let avatarImageURL: URL?

		/// The associated profile view. Optional.
		//		public let associated: ProfileAssociatedDefinition?

		/// The date the profile was last indexed. Optional.
		//		public let indexedAt: Date?

		/// The date and time the profile was created. Optional.
		//		public let createdAt: Date?

		/// The list of metadata relating to the requesting account's relationship with the
		/// subject account. Optional.
		public let viewer: ViewerState?

		/// An array of labels created by the user. Optional.
		//		public let labels: [ComAtprotoLexicon.Label.LabelDefinition]?

	}

	/// A definition model for an actor viewer state.
	///
	/// - Note: From the AT Protocol specification: "Metadata about the requesting account's
	/// relationship with the subject account. Only has meaningful content for authed requests."
	///
	/// - SeeAlso: This is based on the [`app.bsky.actor.defs`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/actor/defs.json
	///
	///TODO: match the lexicon def
	public struct ViewerState: Sendable, Codable {

		/// Indicates whether the requesting account has been muted by the subject
		/// account. Optional.
		public let muted: Bool?

		/// An array of lists that the subject account is muted by.
		//		public let mutedByArray: AppBskyLexicon.Graph.ListViewBasicDefinition?

		/// Indicates whether the authed user has been blocked by the account requested. Optional.
		public let blockedBy: Bool?

		/// A URI which indicates the authed user is blocking the account requested.
		public let blocking: String?

		/// An array of the subject account's lists.
		//		public let blockingByArray: AppBskyLexicon.Graph.ListViewBasicDefinition?

		/// A URI which indicates the authed user is following the account requested.
		public let following: String?

		/// A URI which indicates the authed user is being followed by the account requested.
		public let followedBy: String?

		/// An array of mutual followers. Optional.
		///
		/// - Note: According to the AT Protocol specifications: "The subject's followers whom you
		/// also follow."
		//		public let knownFollowers: KnownFollowers?
	}
}
