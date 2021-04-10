//
//  ViewController.swift
//  StreamAudioPlayer
//
//  Created by Kouhei Suzuki on 2021/04/10.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    private var _player: Player?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let urlString = "http://localhost/sound1.mp3"
        
        guard let url = URL(string: urlString) else {
            return;
        }
        
        _player = try? Player(url: url, playWhenReady: false)
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        guard let player = _player else {
            return;
        }
        
        if player.state == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
}
