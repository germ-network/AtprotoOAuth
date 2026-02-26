//
//  MessagingDelegateRecord.swift
//  ATProtoClient
//
//  Created by Anna Mistele on 5/14/25.
//

import Foundation

extension Lexicon.Com.GermNetwork {
	public struct Declaration: Sendable, Codable {
		/// The identifier of the lexicon.
		///
		/// - Warning: The value must not change.
		//is "id" in the lexicon but avoid conflict with Swift id
		public static let nsid: NSID = "com.germnetwork.declaration"
		//for encoding
		private(set) var id: NSID = Self.nsid

		/// Required, Opaque.
		/// Expected to parse to a SemVer. While the lexicon is fixed, the version applies to the format of opaque content
		public let version: String

		/// Required, Opaque to AppViews (possible future - parse this and validate signature over the DID in keyPackage)
		/// ed25519 public key prefixed with a byte enum
		public let currentKey: LexiconBytes

		/// Required, Opaque to AppViews
		/// Contains MLS KeyPackage(s), and other signature data, and is signed by the currentKey
		public let keyPackage: LexiconBytes?

		/// Optional
		/// Encapsulates the required url and `showButtonTo`  properties to show a button to other users
		public let messageMe: MessageMeInstructions?

		/// Optional, Opaque.
		/// Allows for key rolling
		public let continuityProofs: [Data]?

		enum CodingKeys: String, CodingKey {
			case id = "$type"
			case version
			case currentKey
			case keyPackage
			case messageMe
			case continuityProofs
		}

		public init(from decoder: any Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			self.id =
				try container
				.decode(String.self, forKey: CodingKeys.id)
			guard self.id == Self.nsid else {
				throw ATProtoTypeError.invalidRecordType
			}

			self.version = try container.decode(String.self, forKey: CodingKeys.version)
			self.currentKey = try container.decode(
				LexiconBytes.self, forKey: CodingKeys.currentKey)
			self.keyPackage = try container.decodeIfPresent(
				LexiconBytes.self, forKey: CodingKeys.keyPackage)
			self.messageMe = try container.decodeIfPresent(
				MessageMeInstructions.self, forKey: CodingKeys.messageMe)
			self.continuityProofs = try container.decodeIfPresent(
				[Data].self, forKey: CodingKeys.continuityProofs)
		}

		public init(
			version: String,
			currentKey: Data,
			keyPackage: Data,
			messageMe: MessageMeInstructions?,
			continuityProofs: [Data]?
		) {
			self.version = version
			self.currentKey = .init(bytes: currentKey)
			self.keyPackage = .init(bytes: keyPackage)
			self.messageMe = messageMe
			self.continuityProofs = continuityProofs
		}
	}

	public struct MessageMeInstructions: Sendable, Codable, Equatable, Hashable {
		/// Required
		/// The policy of who can message the user is contained in the keyPackage and is covered by a
		/// signature by the currentKey.
		/// Lifting this out of the opaque keyPackage so the AppView can use it to decide when to render
		/// a link when others view this user’s profile
		public let showButtonTo: ShowButtonTo

		/// Required
		/// This is the url to present to a user Bob who does not have a "com.germnetwork.id" record of their own
		/// This should parse as a URI with empty fragment, where the app should fill in the fragment with
		/// Alice and Bob’s DID’s (see above).
		public let messageMeUrl: String

		public init(
			showButtonTo: ShowButtonTo,
			messageMeUrl: String
		) {
			self.showButtonTo = showButtonTo
			self.messageMeUrl = messageMeUrl
		}
	}

	public enum ShowButtonTo: String, Sendable, Codable {
		case usersIFollow
		case everyone
		case none
	}
}

extension Lexicon.Com.GermNetwork.Declaration: AtprotoRecord {
	public static func mock() -> Lexicon.Com.GermNetwork.Declaration {
		.init(
			version: "1.1.0",
			currentKey: Data("mock".utf8),
			keyPackage: Data("mock".utf8),
			messageMe: nil,
			continuityProofs: nil
		)
	}
}

public struct LexiconBytes: Codable, Equatable, Hashable, Sendable {
	public let bytes: Data

	public init(bytes: Data) {
		self.bytes = bytes
	}

	enum CodingKeys: String, CodingKey {
		case bytes = "$bytes"
	}
}
