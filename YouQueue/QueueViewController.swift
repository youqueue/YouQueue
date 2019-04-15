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
import LNPopupController
import StoreKit
import MediaPlayer

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var endQueueBtn: UIBarButtonItem!

    let cellSpacingHeight: CGFloat = 7
    let applicationMusicPlayer = MPMusicPlayerController.applicationQueuePlayer
    let rowHeight: CGFloat = 87.0
    let songQuery = PFQuery(className: "Song")
    let queueQuery = PFQuery(className: "Queue")

    var songSubscription: Subscription<PFObject>?
    var queueSubscription: Subscription<PFObject>?
    var subscriber: ParseLiveQuery.Client!
    var nowPlayingController: NowPlayingViewController!
    var barController: NowPlayingBarViewController!
    var host: Bool!
    var songs = [Song]()
    var queue: Queue!
    var nowPlaying: Song? {
        willSet(song) {
            self.nowPlayingController.setSong(song: song)
            self.barController.setSong(song: song)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.backgroundColor = .clear
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.showsHorizontalScrollIndicator = false

        self.navigationItem.title = (queue["code"]! as! String)

        self.endQueueBtn.title = host ? "End" : "Leave"

        subscribeToServer()
        fetchData()

        nowPlayingController = (storyboard?.instantiateViewController(withIdentifier: "nowPlaying")
            as! NowPlayingViewController)
        nowPlayingController.queueController = self
        
        barController = (storyboard?.instantiateViewController(withIdentifier: "nowPlayingBar")
            as! NowPlayingBarViewController)
        popupBar.customBarViewController = barController

        if host {
            DispatchQueue.main.async {
                self.presentPopupBar(withContentViewController: self.nowPlayingController,
                                     animated: true, completion: nil)
            }

            appleMusicCheckIfDeviceCanPlayback()
            appleMusicRequestPermission()

            applicationMusicPlayer.repeatMode = .none

            applicationMusicPlayer.beginGeneratingPlaybackNotifications()

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(systemSongDidChange(_:)),
                name: .MPMusicPlayerControllerNowPlayingItemDidChange,
                object: applicationMusicPlayer
            )

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playbackStateDidChange(_:)),
                name: .MPMusicPlayerControllerPlaybackStateDidChange,
                object: applicationMusicPlayer
            )
        }
    }

    func sortSongs(songa: Song, songb: Song) -> Bool {
        let votesa = songa.upvotes.count - songa.downvotes.count
        let votesb = songb.upvotes.count - songb.downvotes.count

        if votesa == votesb {
            return songa.createdAt! < songb.createdAt!
        }

        return votesa > votesb
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.songs.sort(by: sortSongs)

        self.tableView.reloadData()
    }

    @objc func playbackStateDidChange(_ notification: Notification) {
        if self.applicationMusicPlayer.playbackState == .stopped && self.songs.count > 0 {
            self.playNextSong()
        }
    }

    @objc func systemSongDidChange(_ notification: Notification) {
    }

    func fetchData() {
        let query = PFQuery(className: "Song")
        query.whereKey("queue", equalTo: self.queue)
        query.whereKey("played", equalTo: false)

        query.findObjectsInBackground { (songs: [PFObject]?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            } else if let songs = songs {
                self.songs = songs as! [Song]
                self.songs.sort(by: self.sortSongs)

                self.tableView.reloadData()

                self.playNextSong()

                // let range = NSMakeRange(0, self.tableView.numberOfSections)
                // let sections = NSIndexSet(indexesIn: range)
                // self.tableView.reloadSections(sections as IndexSet, with: .automatic)
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.rowHeight
    }

    func playNextSong() {
        self.applicationMusicPlayer.stop()
        self.applicationMusicPlayer.nowPlayingItem = nil
        self.applicationMusicPlayer.setQueue(with: [])
        let unplayedSongs = self.songs.filter { $0.played == false }

        if unplayedSongs.count == 0 {
            return
        }

        let firstSong = unplayedSongs.first!
        firstSong.played = true
        firstSong.saveInBackground { (success, error) in
            if success {
                self.songs = self.songs.filter { $0.songId != firstSong.songId }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                print(error?.localizedDescription)
            }
        }
        self.applicationMusicPlayer.setQueue(with: [String(firstSong.songId)])

        self.barController.setSong(song: firstSong)
        self.nowPlayingController.setSong(song: firstSong)
        self.applicationMusicPlayer.prepareToPlay(completionHandler: { (_) in
            self.applicationMusicPlayer.play()
        })
    }

    func subscribeToServer() {
        songQuery.whereKey("queue", equalTo: self.queue)
            .whereKey("played", equalTo: false)

        queueQuery.whereKey("code", equalTo: self.queue.code)

        subscriber = ParseLiveQuery.Client()
        songSubscription = subscriber.subscribe(songQuery)
        queueSubscription = subscriber.subscribe(queueQuery)

        _ = songSubscription!.handleEvent({ (_, event) in
            switch event {
            case .created(let object):
                self.songs.append(object as! Song)
                self.songs.sort(by: self.sortSongs)

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .updated(let object):
                    let oldsongs = self.songs

                    let newSong = object as! Song

                    self.songs.filter({$0.id == newSong.id}).first?.upvotes = newSong.upvotes
                    self.songs.filter({$0.id == newSong.id}).first?.downvotes = newSong.downvotes

                    self.songs.sort(by: self.sortSongs)

                    self.tableView.beginUpdates()

                    for i in 0...self.songs.count-1 {
                        let newRow = self.songs.index(of: oldsongs[i])
                        self.tableView.moveRow(at: IndexPath(item: 0, section: i),
                                               to: IndexPath(item: 0, section: newRow!))
                    }

                    self.tableView.endUpdates()
            case .left(let object):

                let song = (object as! Song)

                // remove the song
                self.songs = self.songs.filter { $0.songId != song.songId }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            default:
                break
            }
        })

        _ = queueSubscription!.handleEvent({ (_, event) in
            switch event {
            case .updated(let object as Queue):
                if !object.open {
                    UserDefaults.standard.set(false, forKey: "activeQueue")
                    UserDefaults.standard.set("", forKey: "queue")

                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Queue Ended",
                                                      message: "The host has ended the queue", preferredStyle: .alert)

                        if self.host {
                            self.presentingViewController?.presentingViewController?
                                .dismiss(animated: true, completion: nil)
                            self.presentingViewController?.dismiss(animated: true, completion: nil)
                        } else {
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                                self.presentingViewController?.presentingViewController?.dismiss(animated: true,
                                                                                                 completion: nil)
                                self.presentingViewController?.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true)
                        }
                    }
                }
            default:
                break
            }
        })
    }

    @IBAction func upvoteSong(_ sender: UIButton) {

        let id = UIDevice.current.identifierForVendor!.uuidString

        guard let cell = sender.superview?.superview as? SongCell else {
            return // or fatalError() or whatever
        }

        let indexPath = tableView.indexPath(for: cell)

        let song = songs[indexPath!.section]

        if song.upvotes.contains(id) {
            song.upvotes = song.upvotes.filter {$0 != id}
            cell.upvoteButton.setImage(UIImage(named: "arrow-up"), for: .normal)
        } else {
            if song.downvotes.contains(id) {
                song.downvotes = song.downvotes.filter {$0 != id}
                cell.downvoteButton.setImage(UIImage(named: "arrow-down"), for: .normal)
            }

            song.upvotes.append(id)
            cell.upvoteButton.setImage(UIImage(named: "arrow-up-selected"), for: .normal)
        }

        let votes: Int = song.upvotes.count - song.downvotes.count

        cell.voteLabel.text = String(votes)

        song.saveInBackground { (success, error) in
            if success {
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    @IBAction func downvoteSong(_ sender: UIButton) {

        let id = UIDevice.current.identifierForVendor!.uuidString

        guard let cell = sender.superview?.superview as? SongCell else {
            return // or fatalError() or whatever
        }

        let indexPath = tableView.indexPath(for: cell)

        let song = songs[indexPath!.section]

        if song.downvotes.contains(id) {
            song.downvotes = song.downvotes.filter {$0 != id}
            cell.downvoteButton.setImage(UIImage(named: "arrow-down"), for: .normal)
        } else {
            if song.upvotes.contains(id) {
                song.upvotes = song.upvotes.filter {$0 != id}
                cell.upvoteButton.setImage(UIImage(named: "arrow-up"), for: .normal)
            }

            song.downvotes.append(id)
            cell.downvoteButton.setImage(UIImage(named: "arrow-down-selected"), for: .normal)
        }

        let votes: Int = song.upvotes.count - song.downvotes.count

        cell.voteLabel.text = String(votes)

        song.saveInBackground { (success, error) in
            if success {
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    @IBAction func endQueueBtnPressed(_ sender: Any) {

        if host {
            let alert = UIAlertController(title: "End Queue?",
                                          message: "Are you sure you would like to end this queue?",
                                          preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                self.queue.open = false
                do {
                    try self.queue.save()
                } catch {

                }
                self.applicationMusicPlayer.stop()
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
        let song = self.songs[indexPath.section]

        cell.layer.cornerRadius = 7
        let shadowPath2 = UIBezierPath(roundedRect: cell.bounds, cornerRadius: 7)
        cell.layer.masksToBounds = false
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: CGFloat(1.0), height: CGFloat(3.0))
        cell.layer.shadowOpacity = 0.5
        cell.layer.shadowPath = shadowPath2.cgPath

        let id = UIDevice.current.identifierForVendor!.uuidString

        if song.upvotes.contains(id) {
            cell.upvoteButton.setImage(UIImage(named: "arrow-up-selected"), for: .normal)
        } else if song.downvotes.contains(id) {
            cell.downvoteButton.setImage(UIImage(named: "arrow-down-selected"), for: .normal)
        }

        let votes: Int = song.upvotes.count - song.downvotes.count

        cell.voteLabel.text = String(votes)

        cell.songTitleLabel.text = (song["name"] as! String)
        cell.artistName.text = (song["artist"] as! String)
        cell.albumArt.af_setImage(withURL: URL(string: song["albumArt"] as! String)!)
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "searchSong" {
            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! SongRequestViewController
            viewController.queue = self.queue
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.songs.count
    }

    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }

    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

    // swiftlint:disable line_length
    func appleMusicCheckIfDeviceCanPlayback() {
        let serviceController = SKCloudServiceController()
        serviceController.requestCapabilities { (capability: SKCloudServiceCapability, _: Error?) in

            switch capability {

            case []:
                print("The user doesn't have an Apple Music subscription available. Now would be a good time to prompt them to buy one?")
            case SKCloudServiceCapability.musicCatalogPlayback:
                print("The user has an Apple Music subscription and can playback music!")
            case SKCloudServiceCapability.addToCloudMusicLibrary:
                print("The user has an Apple Music subscription, can playback music AND can add to the Cloud Music Library")
            default: break
            }
        }
    }

    func appleMusicRequestPermission() {
        switch SKCloudServiceController.authorizationStatus() {
        case .authorized:
            print("The user's already authorized - we don't need to do anything more here, so we'll exit early.")
            return
        case .denied:
            print("The user has selected 'Don't Allow' in the past - so we're going to show them a different dialog to push them through to their Settings page and change their mind, and exit the function early.")
            return
        case .notDetermined:
            print("The user hasn't decided yet - so we'll break out of the switch and ask them.")
        case .restricted:
            print("User may be restricted; for example, if the device is in Education mode, it limits external Apple Music usage. This is similar behaviour to Denied.")
            return
        }

        SKCloudServiceController.requestAuthorization { (status: SKCloudServiceAuthorizationStatus) in
            switch status {
            case .authorized:
                print("All good - the user tapped 'OK', so you're clear to move forward and start playing.")
            case .denied:
                print("The user tapped 'Don't allow'. Read on about that below...")
            case .notDetermined:
                print("The user hasn't decided or it's not clear whether they've confirmed or denied.")
            default: break
            }
        }
    }
    // swiftlint:enable line_length
}
