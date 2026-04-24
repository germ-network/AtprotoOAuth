//
//  LoginView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoClient
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

	var body: some View {
		Group {
			Section("Session") {
				if viewModel.sessionStorage.sessionArchive != nil {
					Text("Logged in")
				}
				switch (
					viewModel.sessionWrapper,
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
					Button("Restore", action: viewModel.restore)
				case (nil, nil, nil):
					Button("Login", action: login)
				}
			}

			if viewModel.sessionWrapper != nil {
				Section("Auth Session Query") {
					HStack {
						Text("@").foregroundStyle(.blue)
						TextField(
							"username.bsky.social",
							text: $otherHandle
						)
						#if os(iOS)
							.keyboardType(.URL)
							.textInputAutocapitalization(.never)
						#endif
						.autocorrectionDisabled()
						Spacer()
					}
					Button("Make authed fetch") {
						Task {
							try await viewModel.getMetadata(
								for: otherHandle
							)
						}
					}
					if let blocked = viewModel.blocked {
						Text(verbatim: "Blocked: \(blocked)")
					}
					if let blocking = viewModel.blocking {
						Text(verbatim: "Blocking: \(blocking)")
					}
					if let following = viewModel.following {
						Text(verbatim: "Following: \(following)")
					}
					if let followedBy = viewModel.followedBy {
						Text(verbatim: "Followed by: \(followedBy)")
					}
				}
				Section("Block") {
					HStack {
						Text("@").foregroundStyle(.blue)
						TextField(
							"username.bsky.social",
							text: $otherHandle
						)
						#if os(iOS)
							.keyboardType(.URL)
							.textInputAutocapitalization(.never)
						#endif
						.autocorrectionDisabled()
						Spacer()
					}
					if viewModel.blockingTask == nil {
						Button("Block") {
							viewModel.blockUser(otherHandle)
						}
						if let blockResult = viewModel.blockResult {
							Text(blockResult)
						}
					} else {
						ProgressView()
					}
				}
				Section("Message Delegate") {
					Button("Post messaging delegate: users I follow") {
						Task {
							try await viewModel.postMessagingDelegate(
								for: .usersIFollow)
						}
					}
					Button("Post messaging delegate: closed inbox") {
						Task {
							try await viewModel.postMessagingDelegate(
								for: .none)
						}
					}
					Button("Fetch message delegate") {
						Task {
							try await viewModel.getMessageDelegate()
						}
					}
					if let messageDelegate = viewModel.messageDelegate {
						Text(
							verbatim:
								"Key: \(messageDelegate.currentKey.bytes.base64EncodedString())"
						)
						Text(
							verbatim:
								"Version: \(messageDelegate.version)"
						)
						Text(
							verbatim:
								"Message me URL: \(messageDelegate.messageMe?.messageMeUrl ?? "None")"
						)
						Text(
							verbatim:
								"Show button to: \(messageDelegate.messageMe?.showButtonTo.rawValue ?? "None")"
						)
					}
				}
			}
		}
	}

	func login() {
		viewModel.login()
	}
}

#Preview {
	let did = try! Atproto.DID(string: "did:plc:4yvwfwxfz5sney4twepuzdu7")
	LoginView(
		viewModel: .init(
			did: did, handle: "germnetwork.com",
			resolver: ATResolveResolver(resourceFetcher: URLSession.shared))
	)
}
