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
	) async throws {
		let actorPDS = try pds(for: actor).tryUnwrap

		var followers: [Atproto.DID: MockPDS] = [:]

		for _ in 0..<follows {
			do {
				let (follow, followPDS) = try await createDid(
					handle: .mock(),
					bskyProfile: .mock()
				)
				try await actorPDS.follow(did: follow, from: actor)

				if Self.diceRoll(chance: mutualChance) {
					try await followPDS.follow(did: actor, from: follow)
					followers[follow] = followPDS
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

		for (follower, followPDS) in followers {
			if Self.diceRoll(chance: blockChance) {
				try await followPDS.block(did: actor, from: follower)
			}
		}
	}

	static private func diceRoll(chance: Double) -> Bool {
		let boundedChance = min(max(chance, 0), 1)

		let random = Double.random(in: 0..<1)

		return random < boundedChance
	}
}
