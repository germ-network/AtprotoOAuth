//
//  LoginView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoOAuth
import AtprotoTypes
import SwiftUI
import os

struct LoginView: View {
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "LoginView")

	let viewModel: SessionVM

	// Relationally
	@AppStorage("otherHandle") private var otherHandle: String = ""
	@State private var blocked: Bool? = nil
	@State private var blocking: Bool? = nil
	@State private var following: Bool? = nil
	@State private var followedBy: Bool? = nil

	var body: some View {
		Group {
			Section("Session") {
				if viewModel.sessionStorage.sessionArchive != nil {
					Text("Logged in")
				}
				switch (
					viewModel.session,
					viewModel.processingTask,
					viewModel.sessionStorage.sessionArchive,
				) {
				//bug if session but nil sessionArchive
				//_? means non nil
				case (_?, _, _):
					Text("Instantiated session")
					Button("Sleep", action: viewModel.sleep)
					Button("Log out", action: viewModel.logout)
				case (nil, let processing?, _):
					HStack {
						Text(processing.1)
						ProgressView()
					}
				case (nil, nil, _?):
					Text("stored session")
				case (nil, nil, nil):
					Button("Login", action: login)
				}
			}

			if let session = viewModel.session {
				Section("Auth Session Query") {
					HStack {
						Text("@")
						TextField(
							"handle.bsky.social",
							text: $otherHandle)
						Spacer()
					}
					Button("Make authed fetch") {
						getMetadata(session: session.session)
					}
					//						Button("Post messaging delegate") {
					//							Task {
					//								try await postMessagingDelegate()
					//							}
					//						}
					if let blocked {
						Text("Blocked: \(blocked)")
					}
					if let blocking {
						Text("Blocking: \(blocking)")
					}
					if let following {
						Text("Following: \(following)")
					}
					if let followedBy {
						Text("Followed by: \(followedBy)")
					}
				}
			}
		}
	}

	func login() {
		viewModel.login()
	}

	func getMetadata(session: AtprotoOAuthSession) {
		//	func getMetadata(loginViewModel: ATProtoLiteClientViewModel) async throws {
		//		let theirDID = try await ATProtoPublicAPI.getTypedDID(handle: otherHandle)
		//		if let myPDS = try await ATProtoPublicAPI.getPds(for: loginViewModel.did.fullId),
		//			let pdsURL = URL(string: myPDS)
		//		{
		//			let authenticator = try await loginViewModel.getAuthenticator(
		//				pdsURL: pdsURL)
		//			let metadata = try await ATProtoAuthAPI.getAuthedMetadata(
		//				for: theirDID.fullId,
		//				pdsURL: pdsURL,
		//				authenticator: authenticator.authenticator
		//			)
		//			blocking = metadata.blockingURI != nil
		//			blocked = metadata.isBlocked
		//			following = metadata.followingURI != nil
		//			followedBy = metadata.followedByURI != nil
		//		}
		//	}
	}

}

#Preview {
	let did = try! Atproto.DID(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
	LoginView(
		viewModel: .init(did: did, handle: "germnetwork.com")
	)
}
