//
//  AtprotoDIDTests.swift
//  SwiftAtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Testing

struct AtprotoDIDTests {

	@Test func testParse() throws {
		#expect(throws: AtprotoDIDError.invalidPrefix) {
			let _ = try Atproto.DID(fullId: "di:plc:example")
		}

		#expect(throws: AtprotoDIDError.invalidMethod) {
			let _ = try Atproto.DID(fullId: "did:method:example")
		}
	}
}
