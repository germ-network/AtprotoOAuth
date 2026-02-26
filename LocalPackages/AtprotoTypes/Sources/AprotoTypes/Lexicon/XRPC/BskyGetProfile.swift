//
//  BskyGetProfile.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/26/26.
//

import Foundation

extension Lexicon.App.Bsky.Actor {
	public enum GetProfile: XRPCInterface {
		public typealias Result = Lexicon.App.Bsky.Actor.Defs.ProfileViewDetailed

		public static let nsid = "app.bsky.actor.getProfile"

		public struct Parameters: XRPCParameters {
			public let did: ATProtoDID

			public init(did: ATProtoDID) {
				self.did = did
			}

			public func asQueryItems() -> [URLQueryItem] {
				[.init(name: "actor", value: did.fullId)]
			}
		}
	}
}

extension Lexicon.App.Bsky.Actor.Defs.ProfileViewDetailed: Mockable {
	public static func mock() -> Lexicon.App.Bsky.Actor.Defs.ProfileViewDetailed {
		.init(
			did: ATProtoDID.mock().fullId,
			handle: "germnetwork.com",
			displayName: "Germ Network",
			pronouns: "it/them",
			avatar: URL(string: "https://example.com/avatar.jpg"),
			viewer: .init(
				muted: false,
				blockedBy: true,
				blocking: "placeholder",
				following: "placeholder",
				followedBy: "placeholder"
			)
		)
	}
}
