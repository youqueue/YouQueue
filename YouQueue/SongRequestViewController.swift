//
//  SongRequestViewController.swift
//  PlayMySong
//
//  Created by Case Wright on 2/27/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import AlamofireImage
import Parse

class SongRequestViewController: UITableViewController, UISearchBarDelegate {
    
    var songs = [[String:Any?]]()
    var queue: PFObject!
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search For a Song..."
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        self.tableView.rowHeight = 87
        
        let logo = UIImage(named: "Logo_Music_App_1.png")
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        imageView.image = logo!.af_imageAspectScaled(toFit: CGSize(width: 16, height: 16))
        imageView.contentMode = .scaleAspectFit
        
        self.navigationItem.titleView = imageView
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }

    @IBAction func cancelBtnPressed(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return songs.count
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let song = searchController.searchBar.text!
        let parsedSong = song.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "+")
        
        requestSong(song: parsedSong)
    }
    
    func requestSong(song: String) {
        let escapedString = song.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let url = URL(string: "https://itunes.apple.com/search?term=\(escapedString!)&entity=song")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data, response, error) in
            // This will run when the network request returns
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                self.songs = dataDictionary["results"] as! [[String : Any]]
                self.tableView.reloadData()
            }
        }
        task.resume()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongCell

        let song = songs[indexPath.row]
        let albumURL = song["artworkUrl100"] as! String
        
        cell.songTitleLabel.text = song["trackName"] as! String
        cell.albumArt.af_setImage(withURL: URL(string: albumURL)!)
        cell.artistName.text = song["artistName"] as! String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let song = Song()
        
        song.songId = songs[indexPath.row]["trackId"] as! Int
        song.name = songs[indexPath.row]["trackName"] as! String
        song.artist = songs[indexPath.row]["artistName"] as! String
        song.albumArt = songs[indexPath.row]["artworkUrl100"] as! String
        song.votes = 0
        song.queue = queue
        song.played = false
        
        song.saveInBackground() { (success, error) in
            if(success) {
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                print("error: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SongRequestViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}