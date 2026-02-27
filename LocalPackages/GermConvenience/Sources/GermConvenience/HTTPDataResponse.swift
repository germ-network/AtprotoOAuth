//
//  HTTPDataResponse.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation

//type the (data, responese) tuple so we can chain handlers
//these patterns are available in Vapor
public struct HTTPDataResponse: Sendable {
	public let data: Data
	public let response: HTTPURLResponse

	public typealias Requester = @Sendable (URLRequest) async throws -> HTTPDataResponse

	public init(data: Data, response: HTTPURLResponse) {
		self.data = data
		self.response = response
	}

	public func successDecode<R: Decodable>() throws -> R {
		guard response.statusCode >= 200 && response.statusCode < 300 else {
			if let stringResponse = String(data: data, encoding: .utf8) {
				throw
					HTTPResponseError
					.unsuccessfulString(response.statusCode, stringResponse)
			} else {
				throw HTTPResponseError.unsuccessful(response.statusCode, data)
			}
		}
		return try JSONDecoder().decode(R.self, from: data)
	}

	public enum ErrorResult<R: Decodable, E: Decodable> {
		case result(R)
		case error(E, Int)
	}

	public func successErrorDecode<R: Decodable, E: Decodable>(
		resultType: R.Type,
		errorType: E.Type
	) throws -> ErrorResult<R, E> {
		guard response.statusCode >= 200 && response.statusCode < 300 else {
			do {
				let decoded = try JSONDecoder().decode(E.self, from: data)
				return .error(decoded, response.statusCode)
			} catch {
				if let stringResponse = String(data: data, encoding: .utf8) {
					throw
						HTTPResponseError
						.unsuccessfulString(
							response.statusCode, stringResponse)
				} else {
					throw HTTPResponseError.unsuccessful(
						response.statusCode, data)
				}
			}
		}
		return try .result(JSONDecoder().decode(R.self, from: data))
	}
}

public enum HTTPResponseError: Error {
	case unsuccessful(Int, Data)
	case unsuccessfulString(Int, String)
}
