//
//  MockAtmosphere+SocialGraph.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 5/30/26.
//

import AtprotoClientMocks
import AtprotoTypes
import Foundation

extension MockAtmosphere {
	public func setupSocialGraph(
		actor: Atproto.DID,
		follows: UInt,
		//applied to follows.
		mutualChance: Double,
		//if we didn't get enough followers from mutuals, we'll fill out
		minFollowers: UInt,
		//applied to followers in a final pass
		blockChance: Double
	) async throws -> (
		follows: [Atproto.DID],
		followers: [Atproto.DID],
		mutuals: [Atproto.DID],
		blocking: [Atproto.DID]
	) {
		let actorPDS = try pds(for: actor).tryUnwrap

		var followsDids: [Atproto.DID] = []
		var followers: [Atproto.DID: MockPDS] = [:]
		var mutuals: [Atproto.DID] = []
		var blocking: [Atproto.DID] = []

		for _ in 0..<follows {
			do {
				let (follow, followPDS) = try await createDid(
					handle: .mock(),
					bskyProfile: .mock()
				)
				try await actorPDS.follow(did: follow, from: actor)
				followsDids.append(follow)

				if Self.diceRoll(chance: mutualChance) {
					try await followPDS.follow(did: actor, from: follow)
					followers[follow] = followPDS
					mutuals.append(follow)
				}
			} catch {
				Self.logger.error("Setting up follow \(error)")
			}
		}

		//fill in the additional followers
		let remainder = Int(minFollowers) - followers.count
		for _ in 0..<max(0, remainder) {
			do {
				let (follower, followerPDS) = try await createDid(
					handle: .mock(),
					bskyProfile: .mock()
				)
				try await followerPDS.follow(did: actor, from: follower)
				followers[follower] = followerPDS
			} catch {
				Self.logger.error("Setting up follower \(error)")
			}
		}

		for (follower, _) in followers {
			if Self.diceRoll(chance: blockChance) {
				do {
					try await actorPDS.block(did: follower, from: actor)
					blocking.append(follower)
				} catch {
					Self.logger.error("Setting up block \(error)")
				}

			}
		}
		return (
			follows: followsDids,
			followers: .init(followers.keys),
			mutuals: mutuals,
			blocking: blocking
		)
	}

	static private func diceRoll(chance: Double) -> Bool {
		let boundedChance = min(max(chance, 0), 1)

		let random = Double.random(in: 0..<1)

		return random < boundedChance
	}
}
