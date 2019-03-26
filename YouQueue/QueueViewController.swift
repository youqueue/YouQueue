//
//  QueueViewController.swift
//  PlayMySong
//
//  Created by Case Wright on 3/20/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse
import ParseLiveQuery

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var queue: Queue!
    var songSubscription: Subscription<PFObject>?
    var queueSubscription: Subscription<PFObject>?
    var subscriber: ParseLiveQuery.Client!
    
    @IBOutlet weak var endQueueBtn: UIBarButtonItem!
    var host: Bool!
    
    let songQuery = PFQuery(className: "Song")
    let queueQuery = PFQuery(className: "Queue")
    var songs = [PFObject]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 87
        
        self.navigationItem.title = host ? "Join Code: \(queue["code"]!)" : "Queue"
        
        self.endQueueBtn.title = host ? "End" : "Leave"
        
        fetchData()
        
        subscribeToServer()
        // Do any additional setup after loading the view.
    }
    
    func fetchData() {
        let query = PFQuery(className: "Song")
        query.whereKey("queue", equalTo: self.queue)
        
        query.findObjectsInBackground { (songs: [PFObject]?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            } else if let songs = songs {
                self.songs = songs
                
                let range = NSMakeRange(0, self.tableView.numberOfSections)
                let sections = NSIndexSet(indexesIn: range)
                self.tableView.reloadSections(sections as IndexSet, with: .automatic)
            }
        }
    }
    
    func subscribeToServer() -> Void {
        songQuery.whereKey("queue", equalTo: self.queue)
        queueQuery.whereKey("code", equalTo: self.queue.code)
        
        subscriber = ParseLiveQuery.Client()
        songSubscription = subscriber.subscribe(songQuery)
        queueSubscription = subscriber.subscribe(queueQuery)
        
        _ = songSubscription!.handleEvent({ (_, event) in
            switch event {
            case .created(let object):
                self.songs.append(object)
                // do stuff
                DispatchQueue.main.async {
                    let range = NSMakeRange(0, self.tableView.numberOfSections)
                    let sections = NSIndexSet(indexesIn: range)
                    self.tableView.reloadSections(sections as IndexSet, with: .automatic)
                }
            default:
                break // do other stuff or do nothing
            }
        })
        
        _ = queueSubscription!.handleEvent({ (_, event) in
            switch event {
            case .updated(let object as Queue):
                if !object.open {
                    UserDefaults.standard.set(false, forKey: "activeQueue")
                    UserDefaults.standard.set("", forKey: "queue")
                    
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Queue Ended", message: "The host has ended the queue", preferredStyle: .alert)
                        
                        if self.host {
                            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                            self.presentingViewController?.dismiss(animated: true, completion: nil)
                        } else {
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                                self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true)
                        }
                    }
                }
            default:
                break // do other stuff or do nothing
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.songs.count
    }
    
    @IBAction func endQueueBtnPressed(_ sender: Any) {
        
        if host {
            let alert = UIAlertController(title: "End Queue?", message: "Are you sure you would like to end this queue?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.queue.open = false
                do {
                    try self.queue.save()
                } catch {
                    
                }
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            
            self.present(alert, animated: true)
        } else {
            UserDefaults.standard.set(false, forKey: "activeQueue")
            UserDefaults.standard.set("", forKey: "queue")
            
            self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell") as! SongCell
        
        let song = self.songs[indexPath.row]
        
        cell.songTitleLabel.text = song["name"] as! String
        cell.artistName.text = song["artist"] as! String
        cell.albumArt.af_setImage(withURL: URL(string: song["albumArt"] as! String)!)
        
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if(segue.identifier == "searchSong") {
            let nc = segue.destination as! UINavigationController
            let vc = nc.topViewController as! SongRequestViewController
            vc.queue = self.queue
        }
    }
}
