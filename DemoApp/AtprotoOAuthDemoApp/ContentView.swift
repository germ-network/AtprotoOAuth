//
//  ContentView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import ATProtoOAuth
import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
			Tab("Authenticated", systemImage: "person") {
				LoginView()
			}
			Tab("Unauthenticated", systemImage: "smartphone") {
				UnauthenticatedView()
			}
		}
		.padding()
	}
}

#Preview {
	ContentView()
}
