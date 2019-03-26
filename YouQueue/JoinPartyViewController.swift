//
//  JoinPartyViewController.swift
//  PlayMySong
//
//  Created by Case Wright on 3/4/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse
import TextFieldEffects

class JoinPartyViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var codeField: HoshiTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        codeField.delegate = self
        self.modalPresentationCapturesStatusBarAppearance = true
        self.codeField.autocapitalizationType = .allCharacters
        // Do any additional setup after loading the view.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        codeField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        textField.text = (textField.text! as NSString).replacingCharacters(in: range, with: string.uppercased())
        
        return false
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "joinParty" {
            let query = Queue.query()!.whereKey("code", equalTo: codeField.text!)
            
            do {
                let queues = try query.findObjects()
                let queue = queues.first! as! Queue
                
                UserDefaults.standard.set(true, forKey: "activeQueue")
                UserDefaults.standard.set(queue.code, forKey: "queue")
                UserDefaults.standard.set(false, forKey: "host")
                
                let nc = segue.destination as! UINavigationController
                let vc = nc.topViewController as! QueueViewController
                
                vc.host = false
                vc.queue = queue
            } catch {
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "joinParty" {
            let query = Queue.query()!.whereKey("code", equalTo: codeField.text!)
            do {
                let queues = try query.findObjects()
                if queues.count > 0 {
                    return (queues.first as! Queue).open
                } else {
                    let alert = UIAlertController(title: "Queue Not Found", message: "A queue with the specified code could not be found.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                    return false
                }
            } catch {
                return false
            }
        }
        return false
    }
 

}
