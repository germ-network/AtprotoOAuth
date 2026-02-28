//
//  CachedAuthenticatedView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoTypes
import Foundation
import SwiftUI

//Cache values in AppStorage so as to be less annoying
struct CachedAuthenticatedView: View {
	@AppStorage("authHandle") private var storedHandle: String = ""
	@State private var viewModel = CachedAuthenticatedViewModel()

	// Relationally
	@AppStorage("otherHandle") private var otherHandle: String = ""
	@State private var blocked: Bool? = nil
	@State private var blocking: Bool? = nil
	@State private var following: Bool? = nil
	@State private var followedBy: Bool? = nil

	var body: some View {
		List {
			Section("Handle Resolution") {
				switch viewModel.state {
				case .entry(let error):
					HStack {
						TextField("@", text: $storedHandle)
						Button("Check Handle", action: check)
					}
					if let error {
						Text("Error: \(error.localizedDescription)")
							.font(.caption)
					}
					Button("Check Handle, skipping cache", action: forceRecheck)
				case .handleToDid(_):
					HStack {
						Text("Checking @\(storedHandle)...")
						ProgressView()
					}
				case .login(let handle, let did):
					Text("Handle: @\(handle)")
					Text("Resolves to DID \(did.fullId)")
					Button("Start Over", action: viewModel.reset)
				}
			}
			if case .login(let handle, let did) = viewModel.state {
				Section {
					LoginView(handle: handle, did: did)
				}
				//				if loginStore.login != nil {
				//					Section {
				//						HStack {
				//							Text("@")
				//							TextField(
				//								"handle.bsky.social",
				//								text: $otherHandle)
				//							Spacer()
				//						}
				//						Button("Make authed fetch") {
				//							Task {
				//								try await getMetadata()
				//							}
				//						}
				//						Button("Post messaging delegate") {
				//							Task {
				//								try await postMessagingDelegate()
				//							}
				//						}
				//						if let blocked {
				//							Text("Blocked: \(blocked)")
				//						}
				//						if let blocking {
				//							Text("Blocking: \(blocking)")
				//						}
				//						if let following {
				//							Text("Following: \(following)")
				//						}
				//						if let followedBy {
				//							Text("Followed by: \(followedBy)")
				//						}
				//					}
				//				}
			}
		}
	}

	func getMetadata() {}
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

	func postMessagingDelegate() {}

	//	func postMessagingDelegate(
	//		loginViewModel: ATProtoLiteClientViewModel
	//	) async throws {
	//		let myDID = try await ATProtoPublicAPI.getTypedDID(handle: storedHandle)
	//		if let myPDS = try await ATProtoPublicAPI.getPds(for: loginViewModel.did.fullId),
	//			let pdsURL = URL(string: myPDS)
	//		{
	//			let authenticator = try await loginViewModel.getAuthenticator(
	//				pdsURL: pdsURL)
	//			let _ = try await ATProtoAuthAPI.update(
	//				delegateRecord: GermLexicon.MessagingDelegateRecord(
	//					version: "2.3.0",
	//					currentKey: "testingKey".utf8Data,
	//					keyPackage: "testingKeyPackage".utf8Data,
	//					messageMe: GermLexicon.MessageMeInstructions(
	//						showButtonTo: .everyone,
	//						messageMeUrl: "message-me-url.com"
	//					),
	//					continuityProofs: ["proof1".utf8Data, "proof2".utf8Data]
	//				),
	//				for: myDID.fullId,
	//				pdsURL: pdsURL,
	//				authenticator: authenticator.authenticator
	//			)
	//		}
	//	}

	func check() {
		viewModel.check(storedHandle)
	}

	func forceRecheck() {
		viewModel
			.check(
				storedHandle,
				cachePolicy: .reloadIgnoringLocalAndRemoteCacheData
			)
	}
}

#Preview {
	CachedAuthenticatedView()
}
