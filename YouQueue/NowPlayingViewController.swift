//
//  NowPlayingViewController.swift
//  YouQueue
//
//  Created by Case Wright on 4/1/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse
import AlamofireImage
import StoreKit
import MediaPlayer

class NowPlayingViewController: UIViewController {

    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var skipBtn: UIButton!

    var queueController: QueueViewController!
    var applicationMusicPlayer = MPMusicPlayerController.applicationQueuePlayer
    var timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()

        albumArt.layer.cornerRadius = 7
        self.playPauseBtn.imageView?.contentMode = .scaleAspectFit
        self.skipBtn.imageView?.contentMode = .scaleAspectFit
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self,
                                     selector: #selector(timerAction), userInfo: nil, repeats: true)
    }

    @objc func timerAction() {
        let progress = self.applicationMusicPlayer.currentPlaybackTime /
            (self.applicationMusicPlayer.nowPlayingItem?.playbackDuration ?? 0.0)
        self.progressBar.setProgress(Float(progress), animated: false)
    }

    @IBAction func skipSong(_ sender: Any) {
        self.queueController.playNextSong()
    }

    @IBAction func playPauseBtnPressed(_ sender: Any) {
        if self.applicationMusicPlayer.playbackState == .playing {
            self.applicationMusicPlayer.pause()
            self.playPauseBtn.setImage(UIImage(named: "play"), for: .normal)
        } else if self.applicationMusicPlayer.playbackState == .paused {
            self.applicationMusicPlayer.play()
            self.playPauseBtn.setImage(UIImage(named: "pause"), for: .normal)
        }
    }

    func setSong(song: Song?) {

        if song != nil {
            self.albumArt.af_setImage(withURL: get1000x1000AlbumArt(url: song!.albumArt))
            self.titleLabel.text = song?.name
            self.albumLabel.text = song?.artist
        } else {
            self.titleLabel.text = "Not Playing"
            self.albumLabel.text = ""
            self.albumArt.image = UIImage()
        }
    }

    func get1000x1000AlbumArt(url: String) -> URL {
        let largerArt = url.replacingOccurrences(of: "100x100bb", with: "1000x1000bb")

        return URL(string: largerArt)!
    }
}
