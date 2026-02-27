//
//  Test.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import AtprotoTypes
import Testing

struct CIDTests {

	@Test func testDecode() async throws {
		let input = "bafyreibmcnkzbxtciyydktbatjlpgh5hollpov4zvpwtaaq353vyzfbxwu"
		let parsed = try CID(string: input)
		#expect(parsed.string.lowercased() == input.lowercased())
	}

}
