import AtprotoTypes
import Foundation

extension Lexicon.Blue.Microcosm.Identity {

	public enum ResolveMiniDoc: XRPCRequest {
		public struct Result: Sendable, Codable {
			// public let did: Atproto.DID
			public let did: String
			public let handle: AtIdentifier.Handle
			public let pds: URL
			public let signingKey: String

			enum CodingKeys: String, CodingKey {
				case signingKey = "signing_key"
				case did
				case handle
				case pds
			}

			public init(
				did: String,
				handle: AtIdentifier.Handle,
				pds: URL,
				signingKey: String
			) {
				self.did = did
				self.handle = handle
				self.pds = pds
				self.signingKey = signingKey
			}

			public init(from decoder: any Decoder) throws {
				let container = try decoder.container(keyedBy: CodingKeys.self)

				self.did = try container.decode(
					String.self,
					forKey: CodingKeys.did
				)
				self.handle = try container.decode(
					AtIdentifier.Handle.self,
					forKey: CodingKeys.handle
				)
				self.pds = try container.decode(
					URL.self,
					forKey: CodingKeys.pds
				)
				self.signingKey = try container.decode(
					String.self,
					forKey: CodingKeys.signingKey
				)
			}
		}

		public static var nsid: Atproto.NSID { "blue.microcosm.identity.resolveMiniDoc" }

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
	public static func mock() -> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result {
		.init(
			did: Atproto.DID.mock().fullId,
			handle: "germnetwork.com",
			pds: URL(string: "https://blusher.us-east.host.bsky.network")!,
			signingKey: "zQ3shPrWRUXva2mWziWZt1vrjuXUx3E28WfgsAwStMcAmDt93"
		)
	}
}
