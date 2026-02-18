//
//  DiDCacheable.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import OAuthenticator

protocol ATProtoCacheable: Sendable, Equatable {
	associatedtype Inputs: Sendable
	associatedtype Result: Sendable, Codable

	//	typealias FetchClosure = (Inputs) async throws -> Result
	static func fetch(
		inputs: Inputs,
		atprotoClient: ATProtoClientInterface
	) async throws -> Result
}

extension DIDDocument: ATProtoCacheable {
	typealias Inputs = ATProtoDID
	typealias Result = DIDDocument

	static func fetch(
		inputs: ATProtoDID,
		atprotoClient: any ATProtoClientInterface
	) async throws -> DIDDocument {
		try await atprotoClient.resolveDocument(did: inputs)
	}
}

extension ProtectedResourceMetadata: ATProtoCacheable {
	typealias Inputs = String  //host
	typealias Result = ProtectedResourceMetadata

	static func fetch(
		inputs: String,
		atprotoClient: any ATProtoClientInterface
	) async throws -> ProtectedResourceMetadata {
		try await atprotoClient.loadProtectedResourceMetadata(host: inputs)
	}
}
