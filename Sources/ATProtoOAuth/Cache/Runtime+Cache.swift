//
//  Runtime+PDSMetadata.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import OAuthenticator

extension ATProtoOAuthRuntime {
	func resolvePdsUrl(did: ATProtoDID) async throws -> URL {
		let document = try await resolveDidDocument(did: did)
		return try document.pdsUrl
	}

	//has to be actor isolated method
	private func resolveDidDocument(did: ATProtoDID) async throws -> DIDDocument {
		let cache: CacheEntry
		if let existing = didCache[did] {
			cache = existing
		} else {
			cache = .init()
			didCache[did] = cache
		}
		return try await cache.didDocument.fetch(
			input: did,
			atprotoClient: atprotoClient
		)
	}
}

extension ATProtoOAuthRuntime {
	class CacheEntry {
		var didDocument: CacheState<DIDDocument> = .unknown
	}

	struct CachedValue<V: ATProtoCacheable>: Sendable {
		let value: V.Result
		let fetched: Date
	}
	enum CacheState<V: ATProtoCacheable> {
		case unknown
		case fetched(CachedValue<V>)
		case fetching(CachedValue<V>?, Task<V.Result, Error>)

		mutating func fetch(
			input: V.Inputs,
			atprotoClient: ATProtoClientInterface,
		) async throws -> V.Result {
			let priorValue: CachedValue<V>?
			switch self {
			case .unknown:
				priorValue = nil
			case .fetched(let cachedValue):
				return cachedValue.value
			case .fetching(let cachedValue, let task):
				do {
					return try await task.value
				} catch {
					guard let cachedValue else {
						throw error
					}
					return cachedValue.value
				}
			}

			let fetchTask = Task {
				try await V.fetch(
					inputs: input,
					atprotoClient: atprotoClient
				)
			}
			self = .fetching(priorValue, fetchTask)

			do {
				let result = try await fetchTask.value
				self = .fetched(
					.init(value: result, fetched: .now)
				)
				return result
			} catch {
				if let priorValue {
					self = .fetched(priorValue)
				} else {
					self = .unknown
				}
				throw error
			}
		}
	}
}
