//
//  URLRequest+construct.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 2/27/26.
//

import Foundation
import GermConvenience

extension URLRequest {
	static func createRequest(
		url: URL,
		httpMethod: HTTPMethod,
		httpBody: Data? = nil,
		acceptValue: String? = "application/json",
		contentTypeValue: String? = "application/json",
		authorizationValue: String? = nil,
	) -> URLRequest {
		var request = URLRequest(url: url)
		request.httpMethod = httpMethod.rawValue

		if let acceptValue {
			request.addValue(acceptValue, forHTTPHeaderField: "Accept")
		}

		if let authorizationValue {
			request.addValue(authorizationValue, forHTTPHeaderField: "Authorization")
		}

		if let httpBody {
			request.httpBody = httpBody
		}

		// Send the data if it matches a POST or PUT request.
		if httpMethod == .post || httpMethod == .put {
			if let contentTypeValue {
				request.addValue(
					contentTypeValue, forHTTPHeaderField: "Content-Type")
			}
		}

		return request
	}
}
