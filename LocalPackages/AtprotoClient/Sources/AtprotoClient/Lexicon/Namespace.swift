//
//  Namespace.swift
//  AtprotoClient
//
//  Created by Mark @ Germ on 3/16/26.
//

import AtprotoTypes
import Foundation

extension Lexicon {
	public enum Com {
		public enum Atproto {
			public enum Repo {}
			public enum Sync {}
		}
	}

	public enum App {
		public enum Bsky {
			public enum Actor {
				public enum Defs {}
			}
			public enum Graph {}
		}
	}
}

extension Lexicon.Com {
	public enum GermNetwork {}
}
