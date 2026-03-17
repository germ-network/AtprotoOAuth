//
//  AtprotoDIDTests.swift
//  SwiftAtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Foundation
import Testing

struct AtprotoDIDTests {
	@Test func testParse() throws {
		#expect(throws: AtprotoDIDError.invalidPrefix) {
			let _ = try Atproto.DID(string: "di:plc:example.com")
		}

		#expect(throws: AtprotoDIDError.invalidMethod) {
			let _ = try Atproto.DID(string: "did:method:example.com")
		}
	}

	struct Wrapper: Codable {
		let did: Atproto.DID
	}
	static let exampleDidString = "did:plc:example.com"

	@Test func testDirectDecoding() throws {
		let raw = "{ \"did\": \"\(Self.exampleDidString)\" }"

		let decoded = try JSONDecoder().decode(Wrapper.self, from: Data(raw.utf8))

		#expect(decoded.did.stringRepresentation == Self.exampleDidString)
	}

	@Test func testDirectEncoding() throws {
		struct Wrapper: Codable {
			let did: Atproto.DID
		}
		let wrapped = try Wrapper(did: .init(string: Self.exampleDidString))
		let encoded = try JSONEncoder().encode(wrapped)
		let decoded = try JSONSerialization.jsonObject(with: encoded)

		let typedDecoded = try #require(decoded as? [String: String])
		#expect(typedDecoded["did"] == Self.exampleDidString)

	}

}
