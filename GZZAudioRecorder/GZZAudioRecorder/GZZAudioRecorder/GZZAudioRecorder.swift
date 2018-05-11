//
//  FMRecordAlertView.swift
//  client_ios_fm_mod_library
//
//  Created by Jonzzs on 2018/5/9.
//  Copyright © 2018年 FacilityONE. All rights reserved.
//

import UIKit
import AVFoundation

// MARK: - 按钮状态
private enum GZZAudioRecordButtonStatus {
    case record         // 录音
    case stopRecord     // 停止录音
    case play           // 播放
    case stopPlay       // 停止播放
}

// MARK: - 弹出录音界面
public class GZZAudioRecorder: GZZBaseAlertView {

    private let buttonSize: CGFloat = 100.0 // 播放按钮尺寸
    private var audioRecorder: AVAudioRecorder? // 录音对象
    private var audioPlayer: AVAudioPlayer? // 播放对象
    
    private var timer: Timer? // 时间计时器
    private var decibelLink: CADisplayLink? // 分贝计时器
    private var showDecibels = [Float]() // 显示的分贝值
    private var recordDecibels = [Float]() // 录音分贝值
    private var playDecibels = [Float]() // 播放分贝值
    
    private lazy var contentView: UIView = {
        return UIView()
    }()
    
    // 分贝视图
    private lazy var decibelView: UIView = {
        return UIView()
    }()
    
    // 复制图层
    private lazy var replicatorLayer: CAReplicatorLayer = {
        let layer = CAReplicatorLayer()
        layer.instanceCount = 2
        layer.instanceTransform = CATransform3DMakeRotation(.pi, 0, 0, 1)
        return layer
    }()
    
    // 分贝图层
    private lazy var decibelLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.red.cgColor
        layer.masksToBounds = true
        return layer
    }()
    
    // 时间文字
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "0:00"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor(red: 102.0/255.0, green: 102.0/255.0, blue: 102.0/255.0, alpha: 1)
        return label
    }()
    
    // 录音按钮
    private lazy var recordButton: UIButton = {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false
        return button
    }()
    
    // 进度圆条
    private lazy var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor(red: 0x10/255.0, green: 0xae/255.0, blue: 0xff/255.0, alpha: 1).cgColor // 线的颜色
        layer.fillColor = UIColor.clear.cgColor // 填充色
        layer.lineCap = kCALineCapRound // 线头样式
        return layer
    }()
    
    // 按钮状态
    private var buttonStatus: GZZAudioRecordButtonStatus = .record {
        didSet {
            if buttonStatus == .record {
                titleLabel.text = "点击开始录音"
                confirmButton.isHidden = true
                cancelButton.setTitle("取消", for: .normal)
                recordButton.setBackgroundImage(UIImage(named: "audio_record_background"), for: .normal)
                recordButton.setImage(UIImage(named: "audio_record_start"), for: .normal)
            } else if buttonStatus == .stopRecord {
                titleLabel.text = ""
                confirmButton.isHidden = true
                cancelButton.setTitle("取消", for: .normal)
                recordButton.setBackgroundImage(UIImage(named: "audio_record_background"), for: .normal)
                recordButton.setImage(UIImage(named: "audio_record_stop"), for: .normal)
            } else if buttonStatus == .play {
                titleLabel.text = "点击播放录音"
                confirmButton.isHidden = false
                cancelButton.setTitle("重录", for: .normal)
                recordButton.setBackgroundImage(UIImage(named: "audio_record_finish_background"), for: .normal)
                recordButton.setImage(UIImage(named: "audio_record_play"), for: .normal)
            } else if buttonStatus == .stopPlay {
                titleLabel.text = ""
                confirmButton.isHidden = false
                cancelButton.setTitle("重录", for: .normal)
                recordButton.setBackgroundImage(UIImage(named: "audio_record_finish_background"), for: .normal)
                recordButton.setImage(UIImage(named: "audio_record_stop"), for: .normal)
            }
        }
    }
    
    // 录音时间
    private var recordTime: Double = 0 {
        didSet {
            timeLabel.text = String.init(format: "\(Int(recordTime) / 60):%02d", Int(recordTime) % 60)
            setNeedsLayout()
        }
    }
    
    // 播放时间
    private var playTime: Double = 0 {
        didSet {
            timeLabel.text = String.init(format: "\(Int(playTime) / 60):%02d", Int(playTime) % 60)
            setNeedsLayout()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setContentView(contentView)
        contentView.addSubview(decibelView)
        contentView.addSubview(recordButton)
        decibelView.addSubview(timeLabel)
        decibelView.layer.addSublayer(replicatorLayer)
        replicatorLayer.addSublayer(decibelLayer)
        recordButton.layer.addSublayer(progressLayer)
        recordButton.addTarget(self, action: #selector(recordAction), for: .touchUpInside)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let width = contentView.frame.width
        let height = contentView.frame.height
        let padding: CGFloat = 15.0
        let decibelViewHeight = (height - buttonSize) / 2 + padding
        let timeLabelWidth = timeLabel.sizeThatFits(CGSize(width: width, height: height)).width
        decibelView.frame = CGRect(x: 0, y: 0, width: width, height: decibelViewHeight)
        timeLabel.frame = CGRect(x: (width - timeLabelWidth) / 2, y: 0, width: timeLabelWidth, height: decibelViewHeight)
        replicatorLayer.frame = decibelView.layer.bounds
        decibelLayer.frame = CGRect(x: timeLabel.frame.origin.x + timeLabelWidth + padding, y: padding, width: 50.0, height: decibelViewHeight - padding * 2)
        recordButton.frame = CGRect(x: (width - buttonSize) / 2, y: decibelViewHeight, width: buttonSize, height: buttonSize)
    }
    
    /// 录音按钮事件
    @objc private func recordAction() {
        if buttonStatus == .record {
            buttonStatus = .stopRecord
            requestRecordPermission()
        } else if buttonStatus == .stopRecord {
            buttonStatus = .play
            stopRecordAudio()
        } else if buttonStatus == .play {
            buttonStatus = .stopPlay
            startPlayAudio()
        } else if buttonStatus == .stopPlay {
            buttonStatus = .play
            stopPlayAudio()
        }
    }
    
    /// 取消按钮事件
    public override func cancelAction() {
        if buttonStatus == .record || buttonStatus == .stopRecord  {
            hide()
        } else {
            reset()
        }
        deleteAudioRecord() // 重录或取消时删除录音
    }
    
    /// 显示
    public override func show() {
        super.show()
        buttonStatus = .record
    }
    
    /// 隐藏
    public override func hide() {
        super.hide()
        stopRecordAudio()
        stopPlayAudio()
    }
    
    /// 重置
    private func reset() {
        stopRecordAudio()
        stopPlayAudio()
        buttonStatus = .record
        recordTime = 0
        showDecibels.removeAll()
        recordDecibels.removeAll()
        playDecibels.removeAll()
        updateDecibelLayer()
    }
    
    /// 检查麦克风权限
    private func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] (available) in
            DispatchQueue.main.async {
                if available {
                    self?.startRecordAudio() // 开始录音
                } else {
                    print("录音失败，请先检查应用权限设置。")
                }
            }
        }
    }
    
    /// 开始录制声音
    private func startRecordAudio() {
        // 定义并构建一个 URL 来保存音频
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        let recordURL = documentDirectory.appendingPathComponent(dateFormatter.string(from: Date()) + ".wav")
        // 定义音频的编码参数
        let recordSettings = [
            AVSampleRateKey : NSNumber(value: 44100.0), // 声音采样率
            AVFormatIDKey : NSNumber(value: kAudioFormatLinearPCM), // 编码格式
            AVNumberOfChannelsKey : NSNumber(value: 2), // 采集音轨
            AVEncoderAudioQualityKey : NSNumber(value: AVAudioQuality.high.rawValue) // 音频质量
        ]
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord) // 录音模式
            try audioRecorder = AVAudioRecorder(url: recordURL, settings: recordSettings)
        } catch { }
        audioRecorder?.isMeteringEnabled = true // 允许获取分贝值
        audioRecorder?.prepareToRecord() // 准备录音
        audioRecorder?.record() // 开始录音
        startTiming() // 开始计时
    }
    
    /// 结束录制声音
    private func stopRecordAudio() {
        audioRecorder?.stop() // 结束录音
        stopTiming() // 结束计时
        recordDecibels = showDecibels
        if let url = audioRecorder?.url {
            recordTime = AVURLAsset(url: url).duration.seconds // 设置准确的录音时间
        }
    }
    
    /// 开始播放声音
    private func startPlayAudio() {
        // 开始进度条动画
        let lineWidth: CGFloat = 2.0 // 线宽
        let radius = buttonSize / 2 - lineWidth / 2 // 半径
        let center = CGPoint(x: buttonSize / 2, y: buttonSize / 2) // 中心点
        let startAngle = -CGFloat.pi / 2 // 开始角度 -90°
        let endAngle = CGFloat.pi * 2 + startAngle // 结束角度 270°
        let animation = CABasicAnimation(keyPath: "strokeEnd") // 动画
        animation.duration = recordTime
        animation.fromValue = 0
        animation.toValue = 1
        animation.isRemovedOnCompletion = true
        animation.delegate = self
        progressLayer.lineWidth = lineWidth
        progressLayer.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle:endAngle, clockwise: true).cgPath
        progressLayer.add(animation, forKey: nil)
        // 开始播放声音
        if let url = audioRecorder?.url {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) // 扬声器播放
                try audioPlayer = AVAudioPlayer(contentsOf: url)
            } catch { }
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        }
        showDecibels.removeAll()
        playDecibels = recordDecibels
        playTime = 0
        startTiming() // 开始计时
    }
    
    /// 结束播放声音
    private func stopPlayAudio() {
        // 结束进度条动画
        progressLayer.removeAllAnimations()
        progressLayer.path = nil
        audioPlayer?.stop() // 结束播放声音
        stopTiming() // 结束计时
        playTime = recordTime
        showDecibels = recordDecibels
        updateDecibelLayer()
    }
    
    /// 开始计时
    private func startTiming() {
        decibelLink = CADisplayLink(target: self, selector: #selector(updateDecibels))
        if #available(iOS 10.0, *) {
            decibelLink?.preferredFramesPerSecond = 10
        } else {
            decibelLink?.frameInterval = 5
        }
        decibelLink?.add(to: RunLoop.current, forMode: .commonModes)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    /// 结束计时
    private func stopTiming() {
        decibelLink?.invalidate()
        timer?.invalidate()
    }
    
    /// 刷新分贝值
    @objc private func updateDecibels() {
        if buttonStatus == .stopRecord {
            var decibel: Float = 0.0
            if let audioRecorder = audioRecorder {
                let alpha: Float = 0.02 // 音频振幅调解相对值 (越小振幅就越高)
                audioRecorder.updateMeters()
                decibel = pow(10.0, alpha * audioRecorder.averagePower(forChannel: 0)) // 获取分贝值
            }
            if decibel < 0.1 { decibel = 0.1 }
            if decibel > 1.0 { decibel = 1.0 }
            showDecibels.insert(decibel, at: 0)
        } else if buttonStatus == .stopPlay {
            if let decibel = playDecibels.last {
                showDecibels.insert(decibel, at: 0)
                playDecibels.removeLast()
            }
        }
        updateDecibelLayer()
    }
    
    /// 刷新分贝显示
    private func updateDecibelLayer() {
        let decibelWidth: CGFloat = 3.0
        let decibelPadding: CGFloat = 2.0
        let height = decibelLayer.frame.height
        let path = UIBezierPath()
        for index in 0..<showDecibels.count {
            let originX = CGFloat(index) * (decibelWidth + decibelPadding) + decibelWidth
            let decibelHeight = CGFloat(showDecibels[index]) * height
            path.move(to: CGPoint(x: originX, y: height / 2 - decibelHeight / 2))
            path.addLine(to: CGPoint(x: originX, y: height / 2 + decibelHeight / 2))
        }
        decibelLayer.lineWidth = decibelWidth
        decibelLayer.path = path.cgPath
    }
    
    /// 刷新录音和播放时间
    @objc private func updateTime() {
        if buttonStatus == .stopRecord {
            recordTime += 1.0
        } else if buttonStatus == .stopPlay {
            playTime += 1.0
        }
    }
    
    /// 删除录音
    private func deleteAudioRecord() {
        if let url = audioRecorder?.url {
            do {
                try FileManager.default.removeItem(at: url)
            } catch { }
        }
    }
}

// MARK: - CAAnimationDelegate
extension GZZAudioRecorder: CAAnimationDelegate {
    
    /// 动画结束
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            buttonStatus = .play
            stopPlayAudio()
        }
    }
}

// MARK: - 公有接口
extension GZZAudioRecorder {
    
    /// 显示
    public class func showWithConfirmButtonAction(_ action: @escaping (URL?) -> Void) {
        let recordAlertView = GZZAudioRecorder()
        recordAlertView.setConfirmButtonAction {
            action(recordAlertView.audioRecorder?.url)
        }
        recordAlertView.show()
    }
}
