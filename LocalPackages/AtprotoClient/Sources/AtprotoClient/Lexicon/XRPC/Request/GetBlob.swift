//
//  GetBlob.swift
//  AtprotoTypes
//
//  Pulled in by Anna Mistele on 3/3/26.
//  Created by Christopher Jr Riley on 2024-05-20.
//

import AtprotoTypes
import Crypto
import Foundation
import GermConvenience

// https://docs.bsky.app/docs/api/com-atproto-sync-get-blob
// https://lexicon.garden/lexicon/did:plc:6msi3pj7krzih5qxqtryxlzw/com.atproto.sync.getBlob/docs
/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/sync/getBlob.json
extension Lexicon.Com.Atproto.Sync {
	public enum GetBlob: XRPCRequest {
		public typealias Result = Data?
		public static var nsid: Atproto.NSID { "com.atproto.sync.getBlob" }
		public static let acceptValue = "*/*"

		public struct Parameters: QueryParameters {
			/// The DID of the account.
			let did: AtIdentifier

			/// The CID of the blob to fetch.
			let cid: CID

			public init(
				did: AtIdentifier,
				cid: CID
			) {
				self.did = did
				self.cid = cid
			}

			public func asQueryItems() -> [URLQueryItem] {
				return [
					.init(name: "did", value: did.wireFormat),
					.init(name: "cid", value: cid.string),
				]
			}
		}
	}
}

extension Lexicon.Com.Atproto.Sync.GetBlob.Result: Mockable {
	public static func mock() -> Self {
		SymmetricKey(size: .bits256).dataRepresentation
	}
}
