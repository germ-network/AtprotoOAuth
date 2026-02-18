//
//  ATProtoDIDTests.swift
//  SwiftATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import SwiftATProtoTypes
import Testing

struct ATProtoDIDTests {

	@Test func testParse() throws {
		#expect(throws: ATProtoDIDError.invalidPrefix) {
			let _ = try ATProtoDID(fullId: "di:plc:example")
		}

		#expect(throws: ATProtoDIDError.invalidMethod) {
			let _ = try ATProtoDID(fullId: "did:method:example")
		}
	}
}
