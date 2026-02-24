//
//  Runtime+PDSMetadata.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import OAuth
import OAuthenticator

extension ATProtoOAuthClient {
	func resolvePdsUrl(did: ATProtoDID) async throws -> URL {
		try await atprotoClient.plcDirectoryQuery(did)
			.pdsUrl
	}

	func getProtectedResourceMetadata(host: String) async throws -> ProtectedResourceMetadata {
		let cache: CacheEntry<ProtectedResourceMetadata>
		if let existing = protectedResourceCache[host] {
			cache = existing
		} else {
			cache = .init(state: .unknown)
			protectedResourceCache[host] = cache
		}
		return try await cache.fetch(
			input: host,
			atprotoClient: atprotoClient,
			on: self
		)
	}

	func getAuthServerMetadata(host: String) async throws -> ServerMetadata {
		let cache: CacheEntry<ServerMetadata>
		if let existing = authServerCache[host] {
			cache = existing
		} else {
			cache = .init(state: .unknown)
			authServerCache[host] = cache
		}
		return try await cache.fetch(
			input: host,
			atprotoClient: atprotoClient,
			on: self
		)
	}
}

extension ATProtoOAuthClient {
	class CacheEntry<V: ATProtoCacheable> {
		var state: CacheState<V>

		init(state: CacheState<V>) {
			self.state = state
		}

		func fetch(
			input: V.Inputs,
			atprotoClient: ATProtoClientInterface,
			on actor: isolated Actor
		) async throws -> V {
			let priorValue: CachedValue<V>?
			switch state {
			case .unknown:
				priorValue = nil
			case .fetched(let cachedValue):
				if cachedValue.fetched.timeIntervalSinceNow
					< ProtectedResourceMetadata.defaultTTL
				{
					return cachedValue.value
				} else {
					state = .unknown
					//continue with fetch
					priorValue = nil
				}

			case .fetching(let cachedValue, let task):
				do {
					return try await task.value
				} catch {
					guard let cachedValue else {
						throw error
					}
					if cachedValue.fetched.timeIntervalSinceNow
						< ProtectedResourceMetadata.defaultTTL
					{
						return cachedValue.value
					} else {
						state = .unknown
						//continue with fetch
						priorValue = nil
					}
				}
			}

			let fetchTask = Task {
				try await V.fetch(
					inputs: input,
					atprotoClient: atprotoClient
				)
			}
			state = .fetching(priorValue, fetchTask)

			do {
				let result = try await fetchTask.value
				state = .fetched(
					.init(value: result, fetched: .now)
				)
				return result
			} catch {
				if let priorValue {
					state = .fetched(priorValue)
				} else {
					state = .unknown
				}
				throw error
			}
		}
	}

	struct CachedValue<V: ATProtoCacheable>: Sendable {
		let value: V
		let fetched: Date
	}
	enum CacheState<V: ATProtoCacheable> {
		case unknown
		case fetched(CachedValue<V>)
		case fetching(CachedValue<V>?, Task<V, Error>)
	}
}
