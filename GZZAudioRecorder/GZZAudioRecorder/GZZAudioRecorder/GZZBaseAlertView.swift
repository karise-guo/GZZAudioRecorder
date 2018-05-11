//
//  GZZBaseAlertView
//  GZZAudioRecoder
//
//  Created by Jonzzs on 2018/3/15.
//  Copyright © 2018年 Jonzzs All rights reserved.
//

import UIKit

// MARK: - 从底部弹出的提示框
open class GZZBaseAlertView: UIView {
    
    private var contentView: UIView? // 显示内容
    private var alertHeight: CGFloat = 250.0 // 提示框高度
    private var confirmButtonAction: (() -> Void)? // 确定按钮事件
    
    /// 阴影背景
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.alpha = 0
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return view
    }()
    
    /// 提示框背景
    private lazy var backView: UIView = {
        let backView = UIView()
        backView.backgroundColor = .white
        backView.layer.borderColor = UIColor(red: 210.0/255.0, green: 210.0/255.0, blue: 210.0/255.0, alpha: 1).cgColor
        backView.layer.borderWidth = 0.3
        return backView
    }()
    
    /// 顶部视图
    private lazy var topView: UIView = {
        let topView = UIView()
        topView.backgroundColor = UIColor(red: 0xf8/255.0, green: 0xf6/255.0, blue: 0xfa/255.0, alpha: 1)
        topView.layer.borderColor = UIColor(red: 210.0/255.0, green: 210.0/255.0, blue: 210.0/255.0, alpha: 1).cgColor
        topView.layer.borderWidth = 0.3
        return topView
    }()
    
    /// 确定按钮
    public lazy var confirmButton: UIButton = {
        let confirmButton = UIButton()
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(UIColor(red: 0x10/255.0, green: 0xae/255.0, blue: 0xff/255.0, alpha: 1), for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        return confirmButton
    }()
    
    /// 取消按钮
    public lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1), for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
        return cancelButton
    }()
    
    // 标题
    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        backView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: alertHeight)
        addSubview(shadowView)
        addSubview(backView)
        backView.addSubview(topView)
        topView.addSubview(confirmButton)
        topView.addSubview(cancelButton)
        topView.addSubview(titleLabel)
        
        confirmButton.addTarget(self, action: #selector(confirmAction), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureAction)))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let topHeight: CGFloat = 40.0
        let buttonWidth: CGFloat = 70.0
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        shadowView.frame = bounds
        backView.frame.size.height = alertHeight
        topView.frame = CGRect(x: 0, y: 0, width: width, height: topHeight)
        confirmButton.frame = CGRect(x: width - buttonWidth, y: 0, width: buttonWidth, height: topHeight)
        cancelButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: topHeight)
        titleLabel.frame = CGRect(x: buttonWidth, y: 0, width: width - buttonWidth * 2, height: topHeight)
        if let contentView = contentView {
            contentView.frame = CGRect(x: 0, y: topHeight, width: width, height: alertHeight - topHeight)
        }
    }
    
    /// 确定按钮事件
    @objc open func confirmAction() {
        if let action = confirmButtonAction {
            action()
        }
        hide()
    }
    
    /// 取消按钮事件
    @objc open func cancelAction() {
        hide()
    }
    
    /// 点击背景事件
    @objc open func tapGestureAction() {
        hide()
    }
    
    /// 显示
    open func show() {
        UIApplication.shared.keyWindow?.rootViewController?.view.addSubview(self)
        UIView.animate(withDuration: 0.3) { [weak self] in
            if let weakSelf = self {
                weakSelf.shadowView.alpha = 1
                weakSelf.backView.frame.origin.y = UIScreen.main.bounds.height - weakSelf.alertHeight
            }
        }
    }
    
    /// 隐藏
    open func hide() {
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.shadowView.alpha = 0
            self?.backView.frame.origin.y = UIScreen.main.bounds.height
        }) { [weak self] (isComplete) in
            self?.removeFromSuperview()
        }
    }
}

// MARK: - 公有接口
extension GZZBaseAlertView {
    
    /// 设置内容视图
    open func setContentView(_ view: UIView) {
        if let contentView = contentView {
            contentView.removeFromSuperview()
        } else {
            contentView = view
            backView.addSubview(contentView!)
        }
        setNeedsLayout()
    }
    
    /// 设置提示框高度（默认为 250.0）
    open func setAlertHeight(_ height: CGFloat) {
        alertHeight = height
        setNeedsLayout()
    }
    
    /// 设置确定按钮的点击事件
    open func setConfirmButtonAction(_ action: @escaping () -> Void) {
        confirmButtonAction = action
    }
}
