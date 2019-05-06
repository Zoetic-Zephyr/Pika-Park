//
//  UIButtonExtension.swift
//  Pika Park
//
//  Created by 张正 on 2019/5/6.
//  Copyright © 2019 JackZhang. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func pulsate() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.2
        pulse.fromValue = 1.0
        pulse.toValue = 0.9
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 1.0
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: nil)
    }
    
    func pulsate2() {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.duration = 0.1
        pulse.fromValue = 1.0
        pulse.toValue = 0.6
        pulse.autoreverses = true
        pulse.repeatCount = 1
        pulse.initialVelocity = 1.0
        pulse.damping = 1.0
        
        layer.add(pulse, forKey: nil)
    }
}
