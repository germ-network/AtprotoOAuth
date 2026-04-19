//
//  NonceDecoder.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 4/18/26.
//

import Foundation
import GermConvenience
import OAuth4Swift

extension OAuth.DPoP {
	static func decodeAtproto(
		dataResponse: HTTPDataResponse,
		requestUrl: URL,
	) throws -> IndexedNonce? {
		let nonce = dataResponse.response.headerFields[try .dpopNonce.tryUnwrap]
		guard let nonce else {
			return nil
		}

		//henceforth should throw instead of return nil as nonce is expected
		return try IndexedNonce(
			requestUrl: requestUrl,
			nonce: nonce
		)
	}
}
