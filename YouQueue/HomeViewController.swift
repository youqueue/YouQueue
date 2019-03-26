//
//  HomeViewController.swift
//  PlayMySong
//
//  Created by Case Wright on 3/4/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import PMSuperButton
import DeckTransition
import SwiftVideoBackground

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try VideoBackground.shared.play(view: self.view, videoName: "party", videoType: "mp4")
        } catch let error {
            print(error.localizedDescription)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if(UserDefaults.standard.bool(forKey: "activeQueue")) {
            
            let code = UserDefaults.standard.string(forKey: "queue")
            let query = Queue.query()?.whereKey("code", equalTo: code)
            
            do {
                let queues = try query!.findObjects()
                let queue = queues.first! as! Queue
                
                if queue.open {
                    self.performSegue(withIdentifier: "rejoinParty", sender: self)
                } else {
                    UserDefaults.standard.set(false, forKey: "activeQueue")
                }
            } catch {
            }
           
        }
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "rejoinParty") {
            let code = UserDefaults.standard.string(forKey: "queue")
            let host = UserDefaults.standard.bool(forKey: "host")
            let query = Queue.query()?.whereKey("code", equalTo: code)
            
            do {
                let queues = try query!.findObjects()
                let queue = queues.first! as! Queue
                
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! QueueViewController
                
                vc.host = host
                vc.queue = queue
            } catch {
            }
        }
    }

}
