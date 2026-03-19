//
//  SocialGraph.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/2/26.
//

import AtprotoTypes
import Foundation

extension AtprotoClient {
	public func getFollowsStream(
		did: Atproto.DID,
	) async throws -> AsyncThrowingStream<[Atproto.DID], Error> {
		//rely on url caching for this value
		let (stream, continuation) = AsyncThrowingStream<[Atproto.DID], Error>
			.makeStream(bufferingPolicy: .unbounded)

		Task {
			var cursor: String? = nil
			var fetchCount = 0
			do {
				repeat {
					let result:
						(
							records: [Lexicon.App.Bsky.Graph.Follow],
							cursor: String?
						) =
							try await listRecords(
								parameters: .init(
									repo: .did(did),
									limit: 100,  // max
									cursor: cursor,
									reverse: nil
								)
							)
					let followingDids = result.records.compactMap {
						// TODO: Log if any of these fail?
						try? Atproto.DID(string: $0.subject)
					}
					continuation.yield(followingDids)
					cursor = result.cursor
					fetchCount += 1
				} while cursor != nil && fetchCount < ATProtoConstants.maxFetches
				continuation.finish()
			} catch {
				continuation.finish(throwing: error)
			}
		}
		return stream
	}
}
