//
//  NowPlayingBarViewController.swift
//  YouQueue
//
//  Created by Case Wright on 4/1/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import LNPopupController
import AlamofireImage
import StoreKit
import MediaPlayer

class NowPlayingBarViewController: LNPopupCustomBarViewController {
    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    
    let applicationMusicPlayer = MPMusicPlayerController.applicationQueuePlayer

    var queueController: QueueViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.playPauseBtn.imageView?.contentMode = .scaleAspectFit

        albumArt.layer.cornerRadius = 5

        preferredContentSize = CGSize(width: -1, height: 65)
        // Do any additional setup after loading the view.
    }

    override var wantsDefaultPanGestureRecognizer: Bool {
        return false
    }

    @IBAction func playPausePressed(_ sender: Any) {
        self.queueController.playPauseSong()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [unowned self] _ in
            self.preferredContentSize = CGSize(width: -1,
                                               height: self.traitCollection.horizontalSizeClass == .regular ? 45 : 65)
            }, completion: nil)
    }

    func setSong(song: Song?) {
        if song != nil {
            DispatchQueue.main.async {
                self.albumArt.af_setImage(withURL: URL(string: song!.albumArt)!)
                self.titleLabel.text = song?.name
            }
        } else {
            DispatchQueue.main.async {
                self.titleLabel.text = "Not Playing"
                self.albumArt.image = UIImage(named: "Logo_Music_App_1BW")
            }
        }
    }
}
