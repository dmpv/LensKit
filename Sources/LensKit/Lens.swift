//
//  Lens.swift
//  Messenger
//
//  Created by Dmitry Purtov on 10.01.2021.
//  Copyright © 2021 SoftPro. All rights reserved.
//

import Foundation

public struct Lens<StateT, SubstateT> {
    public typealias Get = (StateT) -> SubstateT
    public typealias Set = (inout StateT, SubstateT) -> Void

    public let get: Get
    public let set: Set
}

extension Lens {
    var setting: (StateT, SubstateT) -> StateT {
        return { state, substate in
            var state = state
            set(&state, substate)
            return state
        }
    }

    public init(get: @escaping Get, setting: @escaping (StateT, SubstateT) -> StateT) {
        self.init(
            get: get,
            set: { state, substate in
                state = setting(state, substate)
            }
        )
    }
}

extension Lens {
    func then<SubsubstateT>(_ next: Lens<SubstateT, SubsubstateT>) -> Lens<StateT, SubsubstateT> {
        .init(
            get: { next.get(get($0)) },
            setting: { setting($0, next.setting(get($0), $1)) }
        )
    }

    func then<UnwrappedSubstateT, UnwrappedSubsubstateT>(
        withOptionalChaining next: Lens<UnwrappedSubstateT, UnwrappedSubsubstateT>
    ) -> Lens<StateT, UnwrappedSubsubstateT?> where SubstateT == UnwrappedSubstateT? {
        .init(
            get: { get($0).map(next.get) },
            setting: { state, subsubstate in
                guard let substate = get(state) else { return state }
                if let subsubstate = subsubstate {
                    return setting(state, next.setting(substate, subsubstate))
                } else {
                    assertionFailure(); return state
                }
            }
        )
    }

    func then<UnwrappedSubstateT, UnwrappedSubsubstateT>(
        withOptionalChaining next: Lens<UnwrappedSubstateT, UnwrappedSubsubstateT?>
    ) -> Lens<StateT, UnwrappedSubsubstateT?> where SubstateT == UnwrappedSubstateT? {
        then(withOptionalChaining: next)
            .then(.makeUnwrap(with: nil))
    }
}

extension Lens {
    public func unwrapped<UnwrappedSubstateT>(with defaultState: UnwrappedSubstateT) -> Lens<StateT, UnwrappedSubstateT>
    where SubstateT == UnwrappedSubstateT? {
        then(.makeUnwrap(with: defaultState))
    }

    func wrapped() -> Lens<StateT, SubstateT?> {
        then(.makeWrap())
    }

    static func makeUnwrap(with defaultState: SubstateT) -> Self where StateT == SubstateT? {
        .init(
            get: { optionalState in optionalState ?? defaultState },
            set: { optionalState, state in
                guard let _ = optionalState else { return }
                optionalState = state
            }
        )
    }

    static func makeWrap() -> Lens<StateT, StateT?> {
        .init(
            get: { $0 },
            set: { state, optionalState in
                guard let optionalState = optionalState else { assertionFailure(); return }
                state = optionalState
            }
        )
    }
}

extension Lens {
    public init(_ keyPath: WritableKeyPath<StateT, SubstateT>) {
        get = { $0[keyPath: keyPath] }
        set = { $0[keyPath: keyPath] = $1 }
    }

    public init(_ keyPath: KeyPath<StateT, SubstateT>) {
        get = { $0[keyPath: keyPath] }
        set = { _, _ in assertionFailure("Set is restricted for \(keyPath)") }
    }
}
