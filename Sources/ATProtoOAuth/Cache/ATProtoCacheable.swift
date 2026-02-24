//
//  ATProtoCacheable.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoClient
import ATProtoTypes
import Foundation
import OAuth
import OAuthenticator

protocol ATProtoCacheable: Sendable, Equatable {
	associatedtype Inputs: Sendable
	static var defaultTTL: TimeInterval { get }

	//	typealias FetchClosure = (Inputs) async throws -> Result
	static func fetch(
		inputs: Inputs,
		atprotoClient: ATProtoClientInterface
	) async throws -> Self
}

extension ProtectedResourceMetadata: ATProtoCacheable {
	typealias Inputs = String  //host
	static let defaultTTL: TimeInterval = 60 * 10

	static func fetch(
		inputs: String,
		atprotoClient: any ATProtoClientInterface
	) async throws -> ProtectedResourceMetadata {
		try await atprotoClient.loadProtectedResourceMetadata(host: inputs)
	}
}

extension ServerMetadata: ATProtoCacheable {
	typealias Inputs = String  //host
	static let defaultTTL: TimeInterval = 60 * 10

	static func fetch(
		inputs: String,
		atprotoClient: any ATProtoClientInterface
	) async throws -> ServerMetadata {
		try await atprotoClient.loadAuthServerMetadata(host: inputs)
	}
}
