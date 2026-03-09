//
//  AuthDPopState.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/9/26.
//

import Foundation
import GermConvenience

///A simple actor to manage dpop state for initial auth

public actor AuthDPopState: DPoPSigning {
	nonisolated public let dpopKey: DPoPKey

	let nonceCache: NSCache<NSString, IndexedNonce> = NSCache()

	public init(dpopKey: DPoPKey) {
		self.dpopKey = dpopKey
	}

	public func getNonce(origin: String) -> OAuth.IndexedNonce? {
		nonceCache.object(forKey: origin as NSString)
	}

	public func cacheNonce(response: HTTPDataResponse, requestUrl: URL) throws {
		let indexedNonce = try Self.decode(dataResponse: response, requestUrl: requestUrl)
		if let indexedNonce {
			nonceCache.setObject(indexedNonce, forKey: indexedNonce.origin as NSString)
		}
	}

	static func decode(
		dataResponse: HTTPDataResponse,
		requestUrl: URL,
	) throws -> IndexedNonce? {
		guard let nonce = dataResponse.response.value(forHTTPHeaderField: "DPoP-Nonce")
		else {
			return nil
		}

		//henceforth should throw instead of return nil as nonce is expected
		return try IndexedNonce(
			responseUrl: dataResponse.response.url,
			requestUrl: requestUrl,
			nonce: nonce
		)
	}
}
