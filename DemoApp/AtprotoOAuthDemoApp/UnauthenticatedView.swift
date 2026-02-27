//
//  UnauthenticatedView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 8/1/25.
//

import AtprotoOAuth
import AtprotoTypes
import SwiftUI

struct UnauthenticatedView: View {
	@AppStorage("unauthHandle") var handleEntry: String = "anna.germnetwork.com"

	@State private var followsGerm: Bool?
	@State private var isFollowedByGerm: Bool?

	@State private var follows: [String] = []
	//	@State private var profileRecord: AppBskyLexiconLite.ProfileRecord?
	@State private var handle: String?
	@State private var avatarBlob: Data?
	@State private var bannerBlob: Data?
	@State private var pdsURL: URL?
	@State private var did: Atproto.DID?
	//	@State private var keyPackage: GermLexicon.ArchivedKeyPackageRecord?
	@State private var messagingDelegate: Lexicon.Com.GermNetwork.Declaration?

	@State private var processing: Task<Void, Never>? = nil

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
					Section("ATProto") {
						Text("**DID:** \(did.fullId)")
						Text("**PDS:** \(pdsURL?.absoluteString ?? "N/A")")
						Text("**Handle:** \(handle ?? "N/A")")
					}
					Section("Relationship with Germ") {
						Text(
							"**Follows:** \(followsGerm?.description ?? "N/A")"
						)
						Text(
							"**Is followed by:** \(isFollowedByGerm?.description ?? "N/A")"
						)
					}
					Section("Profile") {
						//						if let profileRecord {
						//							Text(
						//								"**Display name:** \(profileRecord.displayName ?? "N/A")"
						//							)
						//							Text(
						//								"**Bio:** \(profileRecord.description ?? "N/A")"
						//							)
						//						}
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
					//					Section("Key package") {
					//						Text(
					//							keyPackage?.anchorHello
					//								.base64EncodedString()
					//								?? "None found")
					//					}
					Section("Messaging delegate") {
						if let messagingDelegate {
							Text(
								"**Current key:** \(messagingDelegate.currentKey.bytes.base64EncodedString())"
							)
							//							Text(
							//								"**Key package:** \(messagingDelegate.keyPackage?.base64EncodedString() ?? "None")"
							//							)
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
					Section("Follows") {
						ForEach(follows, id: \.self) {
							Text($0)
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
				did = try await LoginVM.fallbackResolve(handle: handleEntry)
			} catch {
				print("Error loading DID: \(error)")
			}
			if let did {
				//consider loading the whole did doc instead
				//				print("Loading PDS...")
				//				do {
				//					if let pds = try await ATProtoPublicAPI.getPds(
				//						for: did.fullId)
				//					{
				//						pdsURL = URL(string: pds)
				//					}
				//				} catch {
				//					print("Error loading PDS: \(error)")
				//				}
				//				if let pdsURL {
				//				print("Loading handle...")
				//				do {
				//					handle = try await ATProtoPublicAPI.getHandle(
				//						did: did.fullId,
				//						pdsURL: pdsURL
				//					)
				//				} catch {
				//					print("Error loading handle: \(error)")
				//				}
				//				print("Loading relationship with Germ...")
				//				do {
				//					let germ = try await ATProtoPublicAPI.getTypedDID(
				//						handle: "germnetwork.com")
				//					followsGerm = try await ATProtoPublicAPI.checkIf(
				//						did: did.fullId,
				//						follows: germ.fullId
				//					)
				//					isFollowedByGerm =
				//					try await ATProtoPublicAPI.checkIf(
				//						did: did.fullId,
				//						isFollowedBy: germ.fullId
				//					)
				//				} catch {
				//					print(
				//						"Error loading relationship with Germ: \(error)"
				//					)
				//				}
				//				print("Loading follows...")
				//				follows = await ATProtoPublicAPI.getFollows(
				//					for: did.fullId,
				//					pdsURL: pdsURL
				//				).0
				//				print("Loading profile...")
				//				do {
				//					profileRecord =
				//					try await ATProtoPublicAPI.getProfileRecord(
				//						did: did.fullId,
				//						pdsURL: pdsURL
				//					)
				//				} catch {
				//					print("Error loading profile: \(error)")
				//				}
				//				print("Loading avatar image...")
				//				if let avatarCid = profileRecord?.avatarBlob?.reference.link
				//				{
				//					do {
				//						avatarBlob =
				//						try await ATProtoPublicAPI.getBlob(
				//							from: did.fullId,
				//							cid: avatarCid,
				//							pdsURL: pdsURL
				//						)
				//					} catch {
				//						print("Error loading avatar: \(error)")
				//					}
				//				}
				//				print("Loading banner image...")
				//				if let bannerCid = profileRecord?.bannerBlob?.reference.link
				//				{
				//					do {
				//						bannerBlob =
				//						try await ATProtoPublicAPI.getBlob(
				//							from: did.fullId,
				//							cid: bannerCid,
				//							pdsURL: pdsURL
				//						)
				//					} catch {
				//						print("Error loading banner: \(error)")
				//					}
				//				}
				//				print("Loading key package...")
				//				do {
				//					keyPackage =
				//					try await ATProtoPublicAPI.getKeyPackage(
				//						did: did.fullId,
				//						pdsURL: pdsURL
				//					)
				//				} catch {
				//					print("Error loading key package: \(error)")
				//				}
				//				print("Loading messaging delegate...")
				//				do {
				//					messagingDelegate =
				//					try await ATProtoPublicAPI
				//						.getGermMessagingDelegate(
				//							did: did.fullId,
				//							pdsURL: pdsURL
				//						)
				//				} catch {
				//					print("Error loading messaging delegate: \(error)")
				//				}
				//				}
			} else {
				follows = []
				//				profileRecord = nil
				avatarBlob = nil
				bannerBlob = nil
				//				keyPackage = nil
				pdsURL = nil
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
