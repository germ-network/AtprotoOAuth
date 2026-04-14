//
//  FallbackResolver.swift
//  AtprotoGerm
//
//  Created by Anna Mistele on 4/8/26.
//

import AtprotoTypes
import GermConvenience
import Microcosm

public struct FallbackResolver: Atproto.Resolver {
	let defaultResolver: Atproto.Resolver
	let fallbackResolver: Atproto.Resolver

	public init(
		defaultResolver: Atproto.Resolver,
		fallbackResolver: Atproto.Resolver
	) {
		self.defaultResolver = defaultResolver
		self.fallbackResolver = fallbackResolver
	}

	public func resolve(handle: Atproto.Handle) async throws
		-> Atproto.DID?
	{
		do {
			return try await defaultResolver.resolve(handle: handle)
		} catch {
			return try await fallbackResolver.resolve(handle: handle)
		}
	}

	public func resolve(did: AtprotoTypes.Atproto.DID) async throws
		-> AtprotoTypes.Atproto.DIDDocument?
	{
		do {
			return try await defaultResolver.resolve(did: did)
		} catch {
			return try await fallbackResolver.resolve(did: did)
		}
	}
	
	public func verifiedResolve(handle: Atproto.Handle) async throws -> Atproto.DIDDocument? {
		do {
			return try await defaultResolver.verifiedResolve(handle: handle)
		} catch {
			return try await fallbackResolver.verifiedResolve(handle: handle)
		}
	}
}
