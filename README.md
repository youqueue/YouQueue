## YouQueue

### App Description
Allows users to collaboratively add songs from Apple Music to a single song queue. Users can vote to move songs
around the queue. The Music will play out of the host, or "DJ", device.

### App Idea Evaluation
- Mobile: This app is necessary for mobile because it utilizes quick access to music through Apple music and
          it allows users to edit the group queue in real time while socializing.
- Story:  This app solves a problem that many people have suffered through. The value of this app is very clear
          when thinking about how many times a friend has queued up a bad song or when hosting an event, how
          many times people give song requests. Our friends would respond very positively to this idea because
          they have encountered the aforementioned problem numberous times.
- Market: The market for this app is very large as the target audience is anyone who listens to music with other
          people. This applies to many people and they will all have at least some interest in checking out this
          product.
- Habit:  This app is very habit forming considering it would be used anytime someone is listening to music around
          others and wants them to be apart of the song choices. The user consumes the app by utilizing its features
          to make their lives easier with song requests. However, it also allows the user to create as they can build
          their own queues with others.
- Scope:  The scope of this app is feasible to complete in the time allotted because the required features to make the
          app function are very small while additional optional features are plentiful.

---

### User Stories (Required)
1. User can create a new queue or join one by a code
2. User can search for songs
3. User can add songs to the queue
4. User can upvote/downvote songs to move them around the queue

### User Stories (Optional)
1. Host can manually adjust the voting threshold needed to remove a song
2. Host has the power to instantly remove a song or move it around the queue
3. Suggested queues will be pop up based on your location
4. User can view who is in the group with them

---

### Flow Navigation
1. Pick Join or Create room
2. If join room: propmted for code
3. If create room: generate a code
4. Tab navigation: Search songs to add|view queue|see group

---

### Wireframes
<img src="https://i.imgur.com/Crzpfak.png" width=600><br>

---

## Schema 
### Models
#### Queue

   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | queueId      | String   | unique id for the user queue (default field) |
   | lat           | Double   | Latitude of Host |
   | lon           | Double   | Longitude of Host |
   | vote_threshold| Integer  | Number of downvotes before a song is removed |
   | allow_duplicated| Boolean | Allow duplicate songs |
   | restrict_location | Boolean | Restrict joining to a certain location |
   | location_min | Double | location distance threshold in meters |
   | createdAt     | DateTime | date when queue is created (default field) |


#### Song
   | Property      | Type     | Description |
   | ------------- | -------- | ------------|
   | songId        | String   | iTunes song ID |
   | name          | String   | Song name |
   | votes         | Integer  | Number of votes |
   | queue         | Pointer to Queue | Queue song belongs to |
   | played        | Boolean  | Whether song has been played already |

### Networking
#### List of network requests by screen
   - Party Queue Screen
      - (Read/GET) Query all songs where Queue is current queue object
         ```swift
         let query = PFQuery(className:"Song")
         query.whereKey("queue", equalTo: queue)
         query.order(byDescending: "votes")
         query.findObjectsInBackground { (songs: [PFObject]?, error: Error?) in
            if let error = error { 
               print(error.localizedDescription)
            } else if let songs = songs {
               print("Successfully retrieved \(songs.count) songs.")
            }
         }
         ```
      - (Create/POST) Create a new vote on a songs
      - (Delete) Delete existing vote
   - Search Song Screen
      - (Create/POST) Submit a song to queue
   - Join Party Screen
      - (Read/GET) Query queue object
