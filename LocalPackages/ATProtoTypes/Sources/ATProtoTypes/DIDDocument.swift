//
//  DIDDocument.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//  Derived from the type in ATProtoKit by CJ Riley
//

import Foundation

/// Represents a DID document in the AT Protocol, containing crucial information fo
/// AT Protocol functionality.
///
/// The DID document includes the decentralized identifier (DID), verification methods, and
/// service endpoints necessary for interacting with the AT Protocol ecosystem, such as
/// authentication and data storage locations.
public struct DIDDocument: Sendable, Codable, Equatable {

	/// An array of context URLs for the DID document, providing additional semantics for
	/// the properties.
	public let context: [String]

	/// The unique identifier of the DID document.
	public let id: String

	/// An array of URIs under which this decentralized identifier (DID) is also known, including
	/// the primary handle URI. Optional.
	public let alsoKnownAs: [String]?

	/// An array of methods for verifying digital signatures, including the public signing key
	/// for the account.
	public let verificationMethod: [VerificationMethod]

	/// An array of service endpoints related to the decentralized identifier (DID), including the
	/// Personal Data Server's (PDS) location.
	public let service: [ATService]

	/// Checks if the ``service`` property array contains items, and if so, sees if `#atproto_pds`
	/// is in the ``ATService/id`` property.
	///
	/// - Returns: An ``ATService`` item.
	///
	/// - Throws: ``DIDDocumentError`` if ``service`` is empty or if none of the items
	/// contain `#atproto_pds`.
	public func checkServiceForATProto() throws -> ATService {
		let services = self.service

		guard services.count > 0 else {
			throw DIDDocumentError.emptyArray
		}

		for service in services {
			if service.id == "#atproto_pds" {
				return service
			}
		}

		throw DIDDocumentError.noATProtoPDSValue
	}

	enum CodingKeys: String, CodingKey {
		case context = "@context"
		case id
		case alsoKnownAs
		case verificationMethod
		case service
	}

	/// Errors relating to the DID Document.
	public enum DIDDocumentError: Error {

		/// The ``DIDDocument/service`` array is empty.
		case emptyArray

		/// None of the items in the ``DIDDocument/service`` array contains a `#atproto_pds`
		/// value in the ``ATService/id`` property.
		case noATProtoPDSValue

		case urlConstructionError
		case missingServiceUrl
	}
	
	public var handle: String? {
		(alsoKnownAs ?? [])
			.filter{ $0.hasPrefix("at://")}
			//TODO: filter for "no path or other URI parts."
			.first
	}
}

/// Describes a method for verifying digital signatures in the AT Protocol, including the public
/// signing key.
public struct VerificationMethod: Sendable, Codable, Equatable {

	/// The unique identifier of the verification method.
	public let id: String

	/// The type of verification method that indicates the cryptographic curve used.
	public let type: String

	/// The controller of the verification method, which matches the
	/// decentralized identifier (DID).
	public let controller: String

	/// The public key, in multibase encoding; used for verifying digital signatures.
	public let publicKeyMultibase: String
}

/// Represents a service endpoint in a DID document, such as the
/// Personal Data Server's (PDS) location.
public struct ATService: Sendable, Codable, Equatable {

	/// The unique identifier of the service.
	public let id: String

	/// The type of service (matching `AtprotoPersonalDataServer`) for use in identifying
	/// the Personal Data Server (PDS).
	public let type: String

	/// The endpoint URL for the service, specifying the location of the service.
	public let serviceEndpoint: URL
}

extension DIDDocument {
	//https://atproto.com/specs/did#did-documents
	//"The first matching entry in the array should be used, and any others ignored. "
	//"an account with no valid PDS location in their DID document is broken"
	public var pdsUrl: URL {
		get throws {
			guard
				let service = service.first(where: {
					$0.type == "AtprotoPersonalDataServer"
				})
			else {
				throw DIDDocumentError.missingServiceUrl
			}
			return service.serviceEndpoint
		}
	}
}

extension DIDDocument {
	public static func mock() throws -> Self {
		guard let serviceEndpoint = URL(string: "https://blusher.us-east.host.bsky.network")
		else {
			throw DIDDocumentError.urlConstructionError
		}
		return .init(
			context: [
				"https://www.w3.org/ns/did/v1",
				"https://w3id.org/security/multikey/v1",
				"https://w3id.org/security/suites/secp256k1-2019/v1",
			],
			id: "did:plc:4yvwfwxfz5sney4twepuzdu7",
			alsoKnownAs: ["at://germnetwork.com"],
			verificationMethod: [
				.init(
					id: "did:plc:4yvwfwxfz5sney4twepuzdu7#atproto",
					type: "Multikey",
					controller: "did:plc:4yvwfwxfz5sney4twepuzdu7",
					publicKeyMultibase:
						"zQ3shPrWRUXva2mWziWZt1vrjuXUx3E28WfgsAwStMcAmDt93"
				)
			],
			service: [
				.init(
					id: "#atproto_pds",
					type: "AtprotoPersonalDataServer",
					serviceEndpoint: serviceEndpoint
				)
			]
		)
	}
}
