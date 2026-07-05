//
//  Router.swift
//  Invention Party
//
//  Replaces expo-router's imperative navigation (router.push / router.back)
//  with a NavigationStack path that screens can drive directly.
//

import Combine
import SwiftUI

enum Route: Hashable {
    case packs
    case aiDeck
    case setup
    case rules
    case round
    case ideaPad
    case judge
    case vote
    case scoreboard
    case podium
}

final class Router: ObservableObject {
    @Published var path: [Route] = []

    /// Whether the last navigation moved *forward* (push/reset) or *back*
    /// (pop/popToRoot). Drives the direction of the handmade page transition.
    @Published var lastWasPush: Bool = true

    /// Equivalent to router.push('/route')
    func push(_ route: Route) {
        lastWasPush = true
        path.append(route)
    }

    /// Equivalent to router.back()
    func pop() {
        guard !path.isEmpty else { return }
        lastWasPush = false
        path.removeLast()
    }

    /// Equivalent to navigating back to the home screen ('/').
    func popToRoot() {
        lastWasPush = false
        path.removeAll()
    }

    /// Reset the stack so it ends on a single screen (used by "Play Again").
    func reset(to route: Route) {
        lastWasPush = true
        path = [route]
    }
}
