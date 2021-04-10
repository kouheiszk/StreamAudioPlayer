//
//  AVPlayerObserver.swift
//  StreamAudioPlayer
//
//  Created by Kouhei Suzuki on 2021/04/11.
//

import Foundation
import AVFoundation

protocol AVPlayerObserverDelegate: class {
  func player(statusDidChange status: AVPlayer.Status)
  func player(didChangeTimeControlStatus status: AVPlayer.TimeControlStatus)
}

class AVPlayerObserver: NSObject {
  private static var context = 0
  private struct AVPlayerKeyPath {
    static let status = #keyPath(AVPlayer.status)
    static let timeControlStatus = #keyPath(AVPlayer.timeControlStatus)
  }
  
  weak var player: AVPlayer? {
    willSet {
      self.stopObserving()
    }
  }
  private(set) var isObserving: Bool = false

  private weak var _delegate: AVPlayerObserverDelegate?
  
  init(player: AVPlayer, delegate: AVPlayerObserverDelegate) {
    self.player = player
    _delegate = delegate
  }
  
  deinit {
    self.stopObserving()
  }
  
  func startObserving() {
    guard let player = player else {
      return
    }
    
    self.stopObserving()
    self.isObserving = true
    
    player.addObserver(self, forKeyPath: AVPlayerKeyPath.status, options: [.new, .initial], context: &AVPlayerObserver.context)
    player.addObserver(self, forKeyPath: AVPlayerKeyPath.timeControlStatus, options: [.new], context: &AVPlayerObserver.context)
  }
  
  func stopObserving() {
    guard let player = player, isObserving else {
      return
    }
    
    player.removeObserver(self, forKeyPath: AVPlayerKeyPath.status, context: &AVPlayerObserver.context)
    player.removeObserver(self, forKeyPath: AVPlayerKeyPath.timeControlStatus, context: &AVPlayerObserver.context)
    
    self.isObserving = false
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &AVPlayerObserver.context, let observedKeyPath = keyPath else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    
    switch observedKeyPath {
    case AVPlayerKeyPath.status:
      self.handleStatusChange(change)
    case AVPlayerKeyPath.timeControlStatus:
      self.handleTimeControlStatusChange(change)
    default:
      break
      
    }
  }
  
  private func handleStatusChange(_ change: [NSKeyValueChangeKey: Any]?) {
    let status: AVPlayer.Status
    if let statusNumber = change?[.newKey] as? NSNumber {
      status = AVPlayer.Status(rawValue: statusNumber.intValue)!
    }
    else {
      status = .unknown
    }
    
    _delegate?.player(statusDidChange: status)
  }
  
  private func handleTimeControlStatusChange(_ change: [NSKeyValueChangeKey: Any]?) {
    let status: AVPlayer.TimeControlStatus
    if let statusNumber = change?[.newKey] as? NSNumber {
      status = AVPlayer.TimeControlStatus(rawValue: statusNumber.intValue)!
      
      _delegate?.player(didChangeTimeControlStatus: status)
    }
  }
  
}

