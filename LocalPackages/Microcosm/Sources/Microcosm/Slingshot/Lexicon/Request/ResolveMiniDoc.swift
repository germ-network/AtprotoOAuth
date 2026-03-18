import AtprotoClient
import AtprotoTypes
import Foundation

extension Lexicon.Blue.Microcosm.Identity {

	public enum ResolveMiniDoc: XRPCRequest {
		public static var nsid: Atproto.NSID { "blue.microcosm.identity.resolveMiniDoc" }

		public struct Result: Sendable, Codable {
			public let did: Atproto.DID
			public let handle: AtIdentifier.Handle
			public let pds: URL
			public let signingKey: String

			enum CodingKeys: String, CodingKey {
				case signingKey = "signing_key"
				case did
				case handle
				case pds
			}
		}

		public struct Parameters: QueryParameters {
			public let identifier: AtIdentifier

			public init(identifier: AtIdentifier) {
				self.identifier = identifier
			}

			public func asQueryItems() -> [URLQueryItem] {
				return [
					.init(name: "identifier", value: identifier.wireFormat)
				]
			}
		}
	}
}

extension Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result: Mockable {
	public static func mock() -> Self {
		.init(
			did: Atproto.DID.mock(),
			handle: "germnetwork.com",
			pds: URL(string: "https://blusher.us-east.host.bsky.network")!,
			signingKey: "zQ3shPrWRUXva2mWziWZt1vrjuXUx3E28WfgsAwStMcAmDt93"
		)
	}
}
