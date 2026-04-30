//
//  ContentView.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import AtprotoOAuth
import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
			Tab("Authenticated", systemImage: "person") {
				LoginDemoView()
			}
			Tab("CachedAuthenticatedView", systemImage: "person") {
				CachedAuthenticatedView()
			}
			Tab("Unauthenticated", systemImage: "smartphone") {
				UnauthenticatedView()
			}
			Tab("Resolver", systemImage: "person") {
				Resolver()
			}
		}
	}
}

#Preview {
	ContentView()
}
