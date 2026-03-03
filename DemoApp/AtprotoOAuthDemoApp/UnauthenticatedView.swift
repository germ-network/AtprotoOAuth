//
//  UnauthenticatedView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 8/1/25.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import SwiftUI

struct UnauthenticatedView: View {
	@AppStorage("unauthHandle") var handleEntry: String = "anna.germnetwork.com"

	@State private var followsGerm: Bool?
	@State private var isFollowedByGerm: Bool?

	@State private var follows: [Atproto.DID] = []
	@State private var profileRecord: Lexicon.App.Bsky.Actor.Profile?
	@State private var handle: String?
	@State private var avatarBlob: Data?
	@State private var bannerBlob: Data?
	@State private var pdsURL: URL?
	@State private var did: Atproto.DID?
	//	@State private var keyPackage: GermLexicon.ArchivedKeyPackageRecord?
	@State private var messagingDelegate: Lexicon.Com.GermNetwork.Declaration?

	@State private var processing: Task<Void, Never>? = nil

	let client = AtprotoClient.init(
		responseProvider: URLSession.defaultProvider
	)

	var body: some View {
		VStack {
			HStack {
				HStack {
					Text("@")

					TextField("Handle", text: $handleEntry)
						#if os(iOS)
							.textInputAutocapitalization(.never)
						#else
						#endif
				}
				.padding()
				.background(RoundedRectangle(cornerRadius: 10).stroke(.gray))
				Button {
					loadAll()
				} label: {
					Group {
						if processing != nil {
							ProgressView()
						} else {
							Image(systemName: "magnifyingglass")
								.foregroundStyle(.white)
						}
					}
					.padding()
					.background(RoundedRectangle(cornerRadius: 10).fill(.blue))
				}
			}
			.padding()

			if let did {
				List {
					Section("Atproto") {
						Text("**DID:** \(did.fullId)")
						Text("**PDS:** \(pdsURL?.absoluteString ?? "N/A")")
						Text("**Handle:** \(handle ?? "N/A")")
					}
					// Authed call
					//					Section("Relationship with Germ") {
					//						Text(
					//							"**Follows:** \(followsGerm?.description ?? "N/A")"
					//						)
					//						Text(
					//							"**Is followed by:** \(isFollowedByGerm?.description ?? "N/A")"
					//						)
					//					}
					Section("Profile") {
						if let profileRecord {
							Text(
								"**Display name:** \(profileRecord.displayName ?? "N/A")"
							)
							Text(
								"**Bio:** \(profileRecord.description ?? "N/A")"
							)
						}
						if let avatarBlob {
							if let image = Image(jpegData: avatarBlob) {
								image
									.resizable(
										resizingMode:
											.stretch
									)
									.scaledToFit()
							}
						}
						if let bannerBlob {
							if let image = Image(jpegData: bannerBlob) {
								image
									.resizable(
										resizingMode:
											.stretch
									)
									.scaledToFit()
							}
						}
					}
					Section("Messaging delegate") {
						if let messagingDelegate {
							Text(
								"**Current key:** \(messagingDelegate.currentKey.bytes.base64EncodedString())"
							)
							Text(
								"**Key package:** \(messagingDelegate.keyPackage?.bytes.base64EncodedString() ?? "None")"
							)
							Text(
								"**Version:** \(messagingDelegate.version)"
							)
							Text(
								"**Continuity proofs:** \(messagingDelegate.continuityProofs?.count ?? 0)"
							)
							Text(
								"**Message me at:** \(messagingDelegate.messageMe?.messageMeUrl ?? "None")"
							)
							Text(
								"**Show button to:** \(messagingDelegate.messageMe?.showButtonTo.rawValue ?? "None")"
							)
						}
					}
					Section("\(follows.count) Follows") {
						ForEach(follows, id: \.self) {
							Text($0.fullId)
						}
					}
				}
			}
		}
	}

	private func loadAll() {
		guard processing == nil else {
			return
		}

		let newTask = Task {
			print("Loading DID...")
			do {
				did = try await LoginDemoVM.fallbackResolve(handle: handleEntry)
			} catch {
				print("Error loading DID: \(error)")
			}

			guard let did else {
				follows = []
				messagingDelegate = nil
				avatarBlob = nil
				bannerBlob = nil
				pdsURL = nil
				return
			}

			// PDS
			print("Loading PDS...")
			do {
				pdsURL = try await client.plcDirectoryQuery(did).pdsUrl
			} catch {
				print("Error loading PDS: \(error)")
			}

			// Handle
			print("Loading handle...")
			do {
				handle = try await client.plcDirectoryQuery(did).handle
			} catch {
				print("Error loading handle: \(error)")
			}

			// Messaging delegate
			print("Loading messaging delegate...")
			do {
				messagingDelegate =
					try await client.getGermMessagingDelegate(
						did: did
					)
			} catch {
				print("Error loading messaging delegate: \(error)")
			}

			// Profile
			print("Loading profile...")
			do {
				profileRecord =
					try await client.getProfile(did: did)
			} catch {
				print("Error loading profile: \(error)")
			}

			// Avatar
			print("Loading avatar image...")
			if let avatarCid = profileRecord?.avatar?.ref.link {
				do {
					avatarBlob = try await client.getBlob(
						did: did,
						cid: .init(string: avatarCid),
					)
				} catch {
					print("Error loading avatar: \(error)")
				}
			}

			// Banner
			print("Loading banner image...")
			if let bannerCid = profileRecord?.banner?.ref.link {
				do {
					bannerBlob = try await client.getBlob(
						did: did,
						cid: .init(string: bannerCid),
					)
				} catch {
					print("Error loading banner: \(error)")
				}
			}

			// Follows
			print("Loading follows...")
			do {
				let stream = try await client.getFollowsStream(did: did)
				follows = []
				for try await batch in stream {
					follows += batch
				}
			} catch {
				print("Error loading follows: \(error)")
			}
		}
		processing = newTask
		Task {
			await newTask.value
			processing = nil
		}
	}
}

extension Image {
	#if os(iOS)
		init?(jpegData: Data) {
			guard let uiImage = UIImage(data: jpegData) else {
				return nil
			}
			self.init(uiImage: uiImage)
		}
	#else
		init?(jpegData: Data) {
			guard let nsImage = NSImage(data: jpegData) else {
				return nil
			}
			self.init(nsImage: nsImage)
		}
	#endif
}

#Preview {
	UnauthenticatedView()
}
