//
//  HTTPDataResponse.swift
//  GermConvenience
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation

//type the (data, response) tuple so we can chain handlers
//these patterns are available in Vapor
public struct HTTPDataResponse: Sendable {
	public let data: Data
	public let response: HTTPURLResponse

	public init(data: Data, response: HTTPURLResponse) {
		self.data = data
		self.response = response
	}

	public func expect(successCode: Int) throws -> Data {
		try expectSuccess(range: successCode...successCode)
	}

	public func expectSuccess(range: RangeExpression<Int> = 200..<300) throws -> Data {
		guard range.contains(response.statusCode) else {
			if let stringResponse = String(data: data, encoding: .utf8) {
				throw
					HTTPResponseError
					.unsuccessfulString(response.statusCode, stringResponse)
			} else {
				throw HTTPResponseError.unsuccessful(response.statusCode, data)
			}
		}
		return data
	}

	public enum ErrorResult<R: Decodable, E: Decodable> {
		case result(R)
		case error(E, Int)
	}

	public func successErrorDecode<R: Decodable, E: Decodable>(
		resultType: R.Type,
		errorType: E.Type,
		successRange: RangeExpression<Int> = 200..<300
	) throws -> ErrorResult<R, E> {
		do {
			let result: R = try expectSuccess(range: successRange)
				.decode()
			return .result(result)
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
}

extension Data {
	public func decode<R: Decodable>() throws -> R {
		try JSONDecoder().decode(R.self, from: self)
	}
}

public enum HTTPResponseError: Error {
	case unsuccessful(Int, Data)
	case unsuccessfulString(Int, String)
}
