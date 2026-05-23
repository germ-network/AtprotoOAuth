//
//  AgentStateMachineTests.swift
//  AtprotoOAuth
//
//  Exercises AtprotoOAuthAgent.startRefresh state transitions without
//  hitting the network. Refresh paths do not invoke the resolver, so a
//  stub conformance is enough.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience
import OAuth4Swift
import Testing

@testable import AtprotoOAuth

@Suite("AtprotoOAuthAgent state machine")
struct AgentStateMachineTests {
	static let clientId = "https://test.example/client.json"
	static let testDID = "did:plc:4yvwfwxfz5sney4twepuzdu7"

	let resolver: Atproto.Resolver = StubResolver()

	private func makeAgent(includeRefreshToken: Bool = true) throws
		-> (
			agent: AtprotoOAuthAgent,
			saveStream: AsyncStream<OAuth.SessionState.TokenState?>,
			originalAccessToken: String
		)
	{
		var archive = OAuth.SessionState.Archive.mock()
		let accessTokenValue = "access-\(UUID().uuidString)"
		let refreshToken: OAuth.RefreshToken? =
			includeRefreshToken
			? .mock(value: "refresh-\(UUID().uuidString)")
			: nil
		archive.tokenState = .mock(
			accessToken: .mock(value: accessTokenValue),
			refreshToken: refreshToken
		)
		let (agent, saveStream) = try AtprotoOAuthAgent.restore(
			archive: .init(did: Self.testDID, session: archive),
			clientId: Self.clientId,
			authFetcher: URLSession.manualRedirect(),
			atprotoResolver: resolver
		)
		return (agent, saveStream, accessTokenValue)
	}

	@Test("startRefresh coalesces concurrent calls into a single Task")
	func coalesce() async throws {
		let (agent, _, _) = try makeAgent()
		let (gate, gateContinuation) =
			AsyncStream<OAuth.SessionState.TokenState?>.makeStream()

		let task1 = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in
				var iter = gate.makeAsyncIterator()
				return await iter.next() ?? nil
			}
		)
		let task2 = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in
				Issue.record(
					"Second refreshClosure should not run while a refresh is in flight"
				)
				return nil
			}
		)
		let first = try #require(task1)
		let second = try #require(task2)
		#expect(first == second)

		gateContinuation.yield(.mock())
		gateContinuation.finish()
		_ = try? await first.value
	}

	@Test("continueCondition returning false skips refresh and leaves state active")
	func skipsWhenConditionFalse() async throws {
		let (agent, _, originalAccessToken) = try makeAgent()
		let result = await agent.startRefresh(
			continueCondition: { _ in false },
			refreshClosure: { _, _ in
				Issue.record(
					"refreshClosure must not run when continueCondition is false"
				)
				return nil
			}
		)
		#expect(result == nil)
		let token = try await agent.authToken
		#expect(token.value == originalAccessToken)
	}

	@Test("refreshClosure returning nil transitions to expired and emits loggedOut")
	func nilResultExpiresSession() async throws {
		let (agent, saveStream, _) = try makeAgent()

		// Subscribe before triggering so we don't race the buffering policy
		// (bufferingNewest(1) keeps only the most recent event).
		var saveIter = saveStream.makeAsyncIterator()
		var updateIter = await agent.updateStream.makeAsyncIterator()

		let task = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in nil }
		)
		let unwrapped = try #require(task)
		await #expect(throws: OAuthSessionError.sessionInactive) {
			_ = try await unwrapped.value
		}

		switch await saveIter.next() {
		case .some(.none):
			break  // expected: stream yielded a nil TokenState on teardown
		case .some(.some):
			Issue.record(
				"saveStream yielded a non-nil TokenState; expected nil on expiry"
			)
		case .none:
			Issue.record("saveStream ended without yielding")
		}

		switch await updateIter.next() {
		case .loggedOut:
			break
		case .none:
			Issue.record("updateStream ended without yielding")
		}

		await #expect(throws: OAuthSessionError.sessionInactive) {
			_ = try await agent.authToken
		}
	}

	@Test("refreshClosure throwing reverts to active and surfaces previous access token")
	func throwRevertsToActive() async throws {
		let (agent, _, originalAccessToken) = try makeAgent()
		struct Boom: Error {}

		let task = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in throw Boom() }
		)
		let unwrapped = try #require(task)
		let returned = try await unwrapped.value
		#expect(returned.value == originalAccessToken)

		let token = try await agent.authToken
		#expect(token.value == originalAccessToken)
	}

	@Test("active state without a refresh token returns nil from startRefresh")
	func noRefreshTokenReturnsNil() async throws {
		let (agent, _, _) = try makeAgent(includeRefreshToken: false)
		let result = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in
				Issue.record(
					"refreshClosure must not run without a refresh token"
				)
				return nil
			}
		)
		#expect(result == nil)
	}

	@Test("successful refresh installs the new access token and stays active")
	func successUpdatesAccessToken() async throws {
		let (agent, saveStream, originalAccessToken) = try makeAgent()
		var saveIter = saveStream.makeAsyncIterator()

		let newAccessTokenValue = "access-\(UUID().uuidString)"
		let newTokenState = OAuth.SessionState.TokenState.mock(
			accessToken: .mock(value: newAccessTokenValue),
			refreshToken: .mock(value: "refresh-\(UUID().uuidString)")
		)

		let task = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in newTokenState }
		)
		let unwrapped = try #require(task)
		let returned = try await unwrapped.value
		#expect(returned.value == newAccessTokenValue)
		#expect(returned.value != originalAccessToken)

		switch await saveIter.next() {
		case .some(.some(let saved)):
			#expect(saved.accessToken.value == newAccessTokenValue)
		case .some(.none):
			Issue.record("saveStream yielded nil; expected the new TokenState")
		case .none:
			Issue.record("saveStream ended without yielding")
		}

		let token = try await agent.authToken
		#expect(token.value == newAccessTokenValue)
	}

	@Test("startRefresh on an expired session returns nil")
	func expiredStateReturnsNil() async throws {
		let (agent, _, _) = try makeAgent()

		// First refresh returns nil → transitions agent into .expired.
		let expireTask = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in nil }
		)
		let unwrappedExpire = try #require(expireTask)
		await #expect(throws: OAuthSessionError.sessionInactive) {
			_ = try await unwrappedExpire.value
		}

		// A subsequent startRefresh hits the .expired branch and returns nil
		// without invoking the closure.
		let result = await agent.startRefresh(
			continueCondition: { _ in true },
			refreshClosure: { _, _ in
				Issue.record(
					"refreshClosure must not run once the session is expired"
				)
				return nil
			}
		)
		#expect(result == nil)
	}
}

private struct StubResolver: Atproto.Resolver {
	func resolve(handle: Atproto.Handle) async throws -> Atproto.DID? { nil }
	func resolve(did: Atproto.DID) async throws -> Atproto.DIDDocument? { nil }
}
