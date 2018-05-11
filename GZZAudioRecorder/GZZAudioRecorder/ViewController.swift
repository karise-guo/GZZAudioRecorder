//
//  ViewController.swift
//  GZZAudioRecorder
//
//  Created by Jonzzs on 2018/5/11.
//  Copyright © 2018年 Jonzzs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let buttonSize: CGFloat = 100.0
        let button = UIButton(frame: CGRect(x: (view.frame.width - buttonSize) / 2, y: (view.frame.height - buttonSize) / 2, width: buttonSize, height: buttonSize))
        button.setTitle("开始录音", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        view.addSubview(button)
    }
    
    @objc func buttonAction() {
        GZZAudioRecorder.showWithConfirmButtonAction { (url) in
            if let url = url {
                print("录音地址：\(url)")
            }
        }
    }
}

