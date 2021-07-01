//
//  Lens+operators.swift
//  Messenger
//
//  Created by Dmitry Purtov on 10.01.2021.
//  Copyright © 2021 SoftPro. All rights reserved.
//

import Foundation

precedencegroup LeftCompositionPrecedence {
  associativity: left
}

infix operator .. : LeftCompositionPrecedence
infix operator .? : LeftCompositionPrecedence

extension Lens {
    static func ..<TransientStateT>(
        lhs: Lens<StateT, TransientStateT>,
        rhs: Lens<TransientStateT, SubstateT>
    ) -> Self {
        lhs.then(rhs)
    }

    static func .?<TransientStateT>(
        lhs: Lens<StateT, TransientStateT?>,
        rhs: Lens<TransientStateT, SubstateT>
    ) -> Lens<StateT, SubstateT?> {
        lhs.then(withOptionalChaining: rhs)
    }

    static func .?<TransientStateT>(
        lhs: Lens<StateT, TransientStateT?>,
        rhs: Lens<TransientStateT, SubstateT?>
    ) -> Lens<StateT, SubstateT?> {
        lhs.then(withOptionalChaining: rhs)
    }
}
