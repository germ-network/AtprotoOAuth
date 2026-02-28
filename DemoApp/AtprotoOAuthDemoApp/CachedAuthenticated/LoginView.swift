//
//  LoginView.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

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

	//	@State private var pds: String? = nil
	//
	//	@State private var authenticatingTask: Task<Void, Error>? = nil

	var body: some View {
		Group {
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

			if let session = viewModel.session {
				Text("logged in")
				Button("Log out", action: viewModel.clearLogin)
			} else {
				Text("Not logged in")
			}

			//			if loginStore.login == nil {
			//				Text("No Login")
			//			} else {
			//				Text("Login Set")
			//				Button("Clear Login", action: viewModel.clearLogin)
			//			}

			//the authenticator is an actor which is hard to introspect
			//from @MainActor
			//			if viewModel._authenticator == nil {
			//				Text("No Authenticator")
			//			} else {
			//				Text("Authenticator Set")
			//			}
		}
	}

	func login() {
		viewModel.login(did: did)
	}
}

#Preview {
	LoginView(
		handle: "germnetwork.com",
		did: try! .init(fullId: "did:plc:4yvwfwxfz5sney4twepuzdu7")
	)
}
