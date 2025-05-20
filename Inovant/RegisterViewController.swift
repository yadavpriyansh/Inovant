//
//  RegisterViewController.swift
//  Inovant
//
//  Created by Priyansh on 19/05/25.
//

import UIKit

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var getOTPButton: UIButton!
    @IBOutlet weak var emailPhoneField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var firstNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailPhoneField.delegate = self
        lastNameField.delegate = self
        firstNameField.delegate = self
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - IBActions
    @IBAction func getOTPPressed(_ sender: UIButton) {
        guard let firstName = firstNameField.text, !firstName.isEmpty else {
            showAlert("First name is required.")
            return
        }
        
        guard let lastName = lastNameField.text, !lastName.isEmpty else {
            showAlert("Last name is required.")
            return
        }
        
        guard let contact = emailPhoneField.text, !contact.isEmpty else {
            showAlert("Email or phone number is required.")
            return
        }
        
        if !isValidEmail(contact) && !isValidPhone(contact) {
            showAlert("Please enter a valid email or phone number.")
            return
        }
        
        let body: [String: Any] = [
            "app_version": "1.0",
            "device_model": UIDevice.current.model,
            "device_token": "",
            "device_type": "I",
            "dob": "",
            "email": isValidEmail(contact) ? contact : "",
            "first_name": firstName,
            "gender": "",
            "last_name": lastName,
            "newsletter_subscribed": 0,
            "os_version": UIDevice.current.systemVersion,
            "password": "",
            "phone": isValidPhone(contact) ? contact : "",
            "phone_code": "965"
        ]
        
        registerUser(with: body)
    }
    
    @IBAction func firstNameFieldEditingDidEnd(_ sender: UITextField) {
        print("First Name: \(sender.text ?? "")")
    }
    
    @IBAction func lastNameFieldEditingDidEnd(_ sender: UITextField) {
        print("Last Name: \(sender.text ?? "")")
    }
    
    @IBAction func phoneEmailFieldEditingDidEnd(_ sender: UITextField) {
        print("Contact: \(sender.text ?? "")")
    }
    
    // API call
    func registerUser(with body: [String: Any]) {
        guard let url = URL(string: "https://admin-cp.rimashaar.com/api/v1/register-new?lang=en") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            showAlert("Failed to encode request.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert("Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.showAlert("No data received from server.")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Response: \(json)")
                        if let status = json["status"] as? Int, status == 200,
                           let userData = json["data"] as? [String: Any],
                           let userId = userData["id"] as? Int {
                            self.performSegue(withIdentifier: "ShowOTPSegue", sender: userId)
                        } else {
                            let message = json["message"] as? String ?? "Registration failed."
                            self.showAlert(message)
                        }
                    }
                } catch {
                    self.showAlert("Unable to parse response.")
                }
            }
        }
        task.resume()
    }
    
    // Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowOTPSegue",
           let otpVC = segue.destination as? OTPViewController,
           let userId = sender as? Int {
            otpVC.userId = userId
        }
    }
    
    // Validation
    func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        let regex = "^[0-9]{7,15}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }
    
    // Alerts
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
