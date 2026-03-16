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
				case .login(let sessionVM):
					Text("Handle: @\(sessionVM.handle)")
					Text(
						"Resolves to DID \(sessionVM.sessionStorage.did.fullId)"
					)
					Button("Start Over", action: viewModel.reset)
				}
			}
			if case .login(let viewModel) = viewModel.state {
				LoginView(viewModel: viewModel)
			}
		}
	}

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
