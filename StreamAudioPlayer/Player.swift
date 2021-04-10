//
//  Player.swift
//  StreamAudioPlayer
//
//  Created by Kouhei Suzuki on 2021/04/11.
//

import Foundation
import AVFoundation

class Player: AVPlayerObserverDelegate {
  private struct Constants {
    static let assetPlayableKey = "playable"
  }

  var state: PlayerState { return _state }
  var volume: Float {
    get { return _avPlayer.volume }
    set { _avPlayer.volume = newValue }
  }
  var currentItem: AVPlayerItem? {
    return _avPlayer.currentItem
  }
  
  private var _asset: AVAsset? = nil
  private var _state: PlayerState = .idle
  private var _playWhenReady: Bool = false
  private var _avPlayer: AVQueuePlayer = AVQueuePlayer()
  private lazy var _playerObserver: AVPlayerObserver = {
    return AVPlayerObserver(player: self._avPlayer, delegate: self)
  }()
  private var _playerLooper: AVPlayerLooper?
  
  init(url: URL, playWhenReady: Bool) throws {
    load(from: url, volume: 1.0, playWhenReady: playWhenReady)
  }
  
  func play() {
    _playWhenReady = true
    _avPlayer.play()
  }
  
  func pause() {
    _playWhenReady = false
    _avPlayer.pause()
  }
  
  func stop() {
    pause()
    reset(hard: true)
  }
  
  private func load(from url: URL, volume: Float, playWhenReady: Bool = true) {
    reset()
    
    _playWhenReady = playWhenReady
    
    if currentItem?.status == .failed {
      recreateAVPlayer()
    }
    
    _asset = AVURLAsset(url: url)
    
    guard let asset = _asset else {
      return
    }
    
    _state = .loading
    
    asset.loadValuesAsynchronously(forKeys: [Constants.assetPlayableKey], completionHandler: { [weak self] in
      guard let self = self else {
        return
      }
      
      var error: NSError? = nil
      let status = asset.statusOfValue(forKey: Constants.assetPlayableKey, error: &error)
      
      DispatchQueue.main.async {
        guard self._asset != nil && asset.isEqual(self._asset) else {
          return
        }
        
        switch status {
        case .loaded:
          let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: [Constants.assetPlayableKey])
          self._avPlayer.replaceCurrentItem(with: playerItem)
          
          self._avPlayer.volume = volume
          self._playerObserver.startObserving()
          self._playerLooper = AVPlayerLooper(player: self._avPlayer, templateItem: playerItem)
        case .failed:
          // TODO: Think load error handling
          // self._delegate?.soundPlayer(failedWithError: error)
          self._asset = nil
        case .cancelled:
          break
        default:
          break
        }
      }
    })
  }
  
  private func reset(hard: Bool = false) {
    _playerLooper?.disableLooping()
    _playerObserver.stopObserving()
    
    _asset?.cancelLoading()
    _asset = nil
    
    if hard {
      _avPlayer.replaceCurrentItem(with: nil)
    }
  }
  
  private func recreateAVPlayer() {
    let player = AVQueuePlayer()
    _playerObserver.player = player
    _avPlayer = player
  }

  // MARK: - AVPlayerObserverDelegate
  
  func player(statusDidChange status: AVPlayer.Status) {
    switch status {
    case .readyToPlay:
      _state = .ready
      if _playWhenReady {
        self.play()
      }
      break
    case .failed:
      // TODO: Think load error handling
      // self._delegate?.soundPlayer(failedWithError: _audioPlayer.error)
      break
    case .unknown:
      break
    @unknown default:
      break
    }
  }
  
  func player(didChangeTimeControlStatus status: AVPlayer.TimeControlStatus) {
    switch status {
    case .paused:
      _state = .paused
    case .playing:
      _state = .playing
    case .waitingToPlayAtSpecifiedRate:
      break
    @unknown default:
      break
    }
  }
}
