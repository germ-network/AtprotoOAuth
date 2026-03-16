//
//  AtprotoSession+Mock.swift
//  AtprotoClient
//
//  Created by Anna Mistele on 3/13/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

public actor AtprotoMockAgent {
	// Might want to check that the appropriate AtprotoRecord type is stored in a given NSID collection
	private var pds: [Atproto.DID: [Atproto.NSID: [Atproto.RecordKey: AtprotoRecord]]] = [:]

	public func putRecord<R: AtprotoRecord>(
		record: R,
		repo: String,
		rkey: String,
	) throws {
		let did = try Atproto.DID(fullId: repo)
		pds[did, default: [:]][R.nsid, default: [:]][rkey] = record
	}

	public func printPds() {
		print(pds)
	}
}

// Get record
extension AtprotoMockAgent {
	func getRecord<R: AtprotoRecord>(
		_ type: R.Type,
		repo: String,
		rkey: String,
		cid: String?
	) throws -> Lexicon.Com.Atproto.Repo.GetRecord<R>.Result {
		let did = try Atproto.DID(fullId: repo)
		guard let repoContents = pds[did] else {
			throw HTTPResponseError.unsuccessfulString(400, "RecordNotFound")
		}
		guard let collectionContents = repoContents[R.nsid] else {
			throw HTTPResponseError.unsuccessfulString(400, "RecordNotFound")
		}
		guard let record = collectionContents[rkey] as? R else {
			throw HTTPResponseError.unsuccessfulString(400, "RecordNotFound")
		}
		// TODO: Mock CID
		return Lexicon.Com.Atproto.Repo.GetRecord<R>.Result(
			uri: UUID().uuidString,
			cid: cid ?? CID.mock().string,
			value: record
		)
	}

	func getRecordResponse<R: AtprotoRecord>(
		_ type: R.Type,
		repo: String,
		rkey: String,
		cid: String?,
		url: URL
	) throws -> GermConvenience.HTTPDataResponse {
		let result = try getRecord(type, repo: repo, rkey: rkey, cid: cid)
		let data = try JSONEncoder().encode(result)
		return .init(
			data: data,
			response: try HTTPURLResponse(
				url: url,
				statusCode: 200,
				httpVersion: nil,
				headerFields: ["Content-Type": "application/json"]
			).tryUnwrap
		)
	}
}

extension AtprotoMockAgent: AtprotoAgent {
	public func authResponse(for request: URLRequest) async throws
		-> GermConvenience.HTTPDataResponse
	{
		let url = try request.url.tryUnwrap
		// pathComponents[0] is "/"
		guard url.pathComponents[1] == "xrpc" else {
			throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
		}

		let queryParameters = getQueryParameters(for: url.query())
		let httpBody = request.httpBody

		switch url.lastPathComponent {
		case Lexicon.Com.Atproto.Repo.getRecordNSID:
			let repo = try queryParameters["repo"].tryUnwrap
			let collection = try queryParameters["collection"].tryUnwrap
			let rkey = try queryParameters["rkey"].tryUnwrap
			let cid = queryParameters["cid"]
			return try getRecordResponse(
				try getLexicon(for: collection),
				repo: repo,
				rkey: rkey,
				cid: cid,
				url: url
			)
		//		case Lexicon.Com.Atproto.Repo.PutRecord<R>.nsid:
		//			break
		//		case Lexicon.Com.Atproto.Repo.ListRecords<R>.nsid:
		//			break
		//		case Lexicon.Com.Atproto.Sync.GetBlob.nsid:
		//			break
		default:
			throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
		}
		throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
	}

	private func getQueryParameters(for queryString: String?) -> [String: String] {
		var queryParameters: [String: String] = [:]
		guard let queryString else {
			return queryParameters
		}
		for param in queryString.split(separator: "&") {
			let fragments = param.split(separator: "=")
			guard fragments.count == 2 else {
				continue
			}
			queryParameters[String(fragments[0])] = String(fragments[1])
		}
		return queryParameters
	}

	private func getLexicon(for collection: String) throws -> AtprotoRecord.Type {
		print(collection)
		switch collection {
		case Lexicon.Com.GermNetwork.Declaration.nsid:
			return Lexicon.Com.GermNetwork.Declaration.self
		case Lexicon.App.Bsky.Graph.Follow.nsid:
			return Lexicon.App.Bsky.Graph.Follow.self
		case Lexicon.App.Bsky.Actor.Profile.nsid:
			return Lexicon.App.Bsky.Actor.Profile.self
		default:
			break
		}
		throw AtprotoMockSessionError.unexpectedRecordType
	}
}

enum AtprotoMockSessionError: Error {
	case unexpectedRecordType
}
