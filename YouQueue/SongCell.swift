//
//  SongCell.swift
//  PlayMySong
//
//  Created by Case Wright on 2/27/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse

class SongCell: UITableViewCell {

    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var artistName: UILabel!
    
    var song: PFObject!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        songTitleLabel.sizeToFit()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
