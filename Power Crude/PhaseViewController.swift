//
//  PhaseViewControllerProtocol.swift
//  Power Crude
//
//  Created by William Everett on 1/11/20.
//  Copyright © 2020 William Everett. All rights reserved.
//

import Foundation
import Cocoa

protocol PhaseViewControllerDelegate: AnyObject {
    func phaseCompleted(viewController : PhaseViewController)
}


class PhaseViewController: NSViewController {
    weak var gameState : GameState?
    weak var delegate : PhaseViewControllerDelegate?
}
