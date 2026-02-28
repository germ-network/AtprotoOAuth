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

//ATProtoLiteClientViewModel can't actually tell you if a login exists without
//async consulting its LoginStorage

struct LoginView: View {
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "LoginView")

	let handle: String
	let did: Atproto.DID

	let viewModel = LoginVM()

	// Relationally
	@AppStorage("otherHandle") private var otherHandle: String = ""
	@State private var blocked: Bool? = nil
	@State private var blocking: Bool? = nil
	@State private var following: Bool? = nil
	@State private var followedBy: Bool? = nil

	var body: some View {
		Group {
			Section {
				//This would normally be automatically sequenced, but
				//making this manual for the sake of testbed
				if viewModel.authenticatingTask == nil {
					Button("Login", action: login)
				} else {
					HStack {
						Text("Authenticating....")
						ProgressView()
					}
				}

				if viewModel.session != nil {
					Text("logged in")
					Button("Log out", action: viewModel.clearLogin)
				} else {
					Text("Not logged in")
				}
				//the authenticator is an actor which is hard to introspect
				//from @MainActor
				//			if viewModel._authenticator == nil {
				//				Text("No Authenticator")
				//			} else {
				//				Text("Authenticator Set")
				//			}
			}
			if let session = viewModel.session {
				Section {
					HStack {
						Text("@")
						TextField(
							"handle.bsky.social",
							text: $otherHandle)
						Spacer()
					}
					Button("Make authed fetch") {
						getMetadata(session: session)
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
		viewModel.login(did: did)
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
	LoginView(
		handle: "germnetwork.com",
		did: try! .init(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
	)
}
