//
//  HostOptionsViewController.swift
//  PlayMySong
//
//  Created by Case Wright on 3/20/19.
//  Copyright © 2019 Case Wright. All rights reserved.
//

import UIKit
import Parse

class HostOptionsViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var locationRadiusLabel: UILabel!
    @IBOutlet weak var locationRadiusInput: UITextField!
    @IBOutlet weak var locationRadiusUnitLabel: UILabel!

    @IBOutlet weak var duplicateSongsSwitch: UISwitch!
    @IBOutlet weak var useLocationSwitch: UISwitch!
    @IBOutlet weak var voteThresholdSwitch: UISwitch!
    @IBOutlet weak var voteThresholdInput: UITextField!

    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()

        self.modalPresentationCapturesStatusBarAppearance = true
        // Do any additional setup after loading the view.
    }

    @IBAction func locationToggleChanged(_ sender: UISwitch) {
        locationRadiusLabel.isEnabled = sender.isOn
        locationRadiusInput.isEnabled = sender.isOn
        locationRadiusUnitLabel.isEnabled = sender.isOn
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func createParty(_ sender: Any) {

    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "createParty" {
            let queue = Queue()
            let code = self.randomString(length: 6)

            // Set queue options
            queue.code = code

            if useLocationSwitch.isOn {

                var currentLocation: CLLocation!

                if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
                    CLLocationManager.authorizationStatus() ==  .authorizedAlways {

                    currentLocation = locationManager.location

                    queue.lat = currentLocation.coordinate.latitude
                    queue.long = currentLocation.coordinate.longitude
                    queue.restrictLocation = true
                    queue.locationMin = Double(locationRadiusInput.text!)!
                } else {
                    queue.restrictLocation = false
                }
            } else {
                queue.restrictLocation = false
            }

            queue.voteThreshold = voteThresholdSwitch.isOn ? Int(voteThresholdInput.text!)! : -1
            queue.allowDuplicated = duplicateSongsSwitch.isOn
            queue.open = true

            queue.saveInBackground { (success, error) in
                if success {
                    print("Queue created")
                    UserDefaults.standard.set(true, forKey: "activeQueue")
                    UserDefaults.standard.set(code, forKey: "queue")
                    UserDefaults.standard.set(true, forKey: "host")
                } else {
                    print("error: \(String(describing: error?.localizedDescription))")
                }
            }

            let navigationController = segue.destination as! UINavigationController
            let viewController = navigationController.topViewController as! QueueViewController

            viewController.host = true
            viewController.queue = queue
        }
    }

    func randomString(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let charSet = CharacterSet(charactersIn: "0123456789").inverted
        let filtered = string.components(separatedBy: charSet).joined(separator: "")
        let basicTest: Bool = string == filtered
        return basicTest
    }
}
