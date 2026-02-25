//
//  GetRepositoryRecord.swift
//
//
//  Created by Christopher Jr Riley on 2024-02-08.
//

import ATProtoTypes
import Foundation

extension ATProtoClient {

	/// Searches for and validates a record from the repository.
	///
	/// - Note: According to the AT Protocol specifications: "Get a single record from a
	/// repository. Does not require auth."
	///
	/// - SeeAlso: This is based on the [`com.atproto.repo.getRecord`][github] lexicon.
	///
	/// [github]: https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/getRecord.json
	///
	/// - Parameters:
	///   - repository: The repository that owns the record.
	///   - collection: The Namespaced Identifier (NSID) of the record.
	///   - recordKey: The record key of the record.
	///   - recordCID: The CID hash of the record. Optional.
	/// - Returns: The record itself, as well as its URI and CID.
	///
	/// - Throws: An ``ATProtoError``-conforming error type, depending on the issue. Go to
	/// ``ATAPIError`` and ``ATRequestPrepareError`` for more details.
	public func getRepository<Result: AtprotoRecord>(
		recordType: Result.Type,
		repo: AtIdentifier,
		recordKey: RecordKey,
		pdsUrl: URL,
		recordCID: CID? = nil,
	) async throws -> Lexicon.Com.Atproto.Repo.GetRecordOutput<Result>? {
		var queryItems: [URLQueryItem] = [
			.init(name: "repo", value: repo.wireFormat),
			.init(name: "collection", value: Result.nsid),
			.init(name: "rkey", value: recordKey),
		]

		if let recordCID {
			queryItems.append(.init(name: "cid", value: recordCID.string))

		}

		let requestUrl = try constructGetRecordURL(
			serviceUrl: pdsUrl,
			queryItems: queryItems
		)

		let request = createRequest(
			url: requestUrl,
			httpMethod: .get,
			authorizationValue: nil
		)

		let (result, response) = try await responseProvider(request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw ATProtoClientError.requestFailed(
				responseCode: nil
			)
		}
		guard let httpResponse = response as? HTTPURLResponse,
			httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
		else {
			if httpResponse.statusCode == 400 {
				let errorResult = try JSONDecoder().decode(
					Lexicon.Com.Atproto.Repo.GetRecordError.self,
					from: result
				)
				if errorResult.error == "RecordNotFound" {
					return nil
				}
			}

			throw ATProtoClientError.requestFailed(
				responseCode: (response as? HTTPURLResponse)?.statusCode
			)
		}
		return try JSONDecoder()
			.decode(
				Lexicon.Com.Atproto.Repo.GetRecordOutput.self,
				from: result
			)
	}

	private func constructGetRecordURL(
		serviceUrl: URL,
		queryItems: [URLQueryItem]
	) throws -> URL {
		//probably upstream, check correct serviceUrl (GER-1502)
		var components = URLComponents()
		//though the spec allows it, don't allow http
		components.scheme = "https"
		guard let host = serviceUrl.host else {
			throw ATProtoClientError.improperServiceUrl
		}
		components.host = host
		components.port = serviceUrl.port
		components.path = "/xrpc/com.atproto.repo.getRecord"
		components.queryItems = queryItems
		guard let url = components.url else {
			throw ATProtoClientError.couldntConstructUrl
		}
		return url
	}

	private func createRequest(
		url: URL,
		httpMethod: HTTPMethod,
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

//from Dave Delong
public struct HTTPMethod: Hashable, Sendable {
	public static let get = HTTPMethod(rawValue: "GET")
	public static let post = HTTPMethod(rawValue: "POST")
	public static let put = HTTPMethod(rawValue: "PUT")
	public static let delete = HTTPMethod(rawValue: "DELETE")

	public let rawValue: String
}
