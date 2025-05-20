//
//  OTPViewController.swift
//  Inovant
//
//  Created by Priyansh on 19/05/25.
//

import UIKit

class OTPViewController: UIViewController, UITextFieldDelegate {
    
    // Textfields mapings
    @IBOutlet weak var oTPField1: UITextField!
    @IBOutlet weak var oTPField2: UITextField!
    @IBOutlet weak var oTPField3: UITextField!
    @IBOutlet weak var oTPField4: UITextField!
    @IBOutlet weak var oTPField5: UITextField!
    
    // Recieving userId from RegisterViewController
    var userId: Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextFields()
    }
    
    // Configuring the fields at once
    private func configureTextFields() {
        let fields = [oTPField1, oTPField2, oTPField3, oTPField4, oTPField5]
        for field in fields {
            field?.delegate = self
            field?.keyboardType = .numberPad
            field?.textAlignment = .center
            field?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        }
    }
    
    // OTP fields focus shifter
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text, text.count == 1 else { return }
        
        switch textField {
        case oTPField1:
            oTPField2.becomeFirstResponder()
        case oTPField2:
            oTPField3.becomeFirstResponder()
        case oTPField3:
            oTPField4.becomeFirstResponder()
        case oTPField4:
            oTPField5.becomeFirstResponder()
        case oTPField5:
            oTPField5.resignFirstResponder()
            autoVerifyOTPIfReady()
        default:
            break
        }
    }
    
    private func autoVerifyOTPIfReady() {
        guard let digit1 = oTPField1.text,
              let digit2 = oTPField2.text,
              let digit3 = oTPField3.text,
              let digit4 = oTPField4.text,
              let digit5 = oTPField5.text,
              !digit1.isEmpty, !digit2.isEmpty, !digit3.isEmpty, !digit4.isEmpty, !digit5.isEmpty else {
            return
        }
        
        let otpCode = digit1 + digit2 + digit3 + digit4 + digit5
        
        guard let userId = userId else {
            showAlert("Missing user ID.")
            return
        }
        
        verifyOTP(code: otpCode, userId: userId)
        
    }
    
    private func clearOTPFields() {
        oTPField1.text = ""
        oTPField2.text = ""
        oTPField3.text = ""
        oTPField4.text = ""
        oTPField5.text = ""
    }
    
    // API Call
    func verifyOTP(code: String, userId: Int) {
        guard let url = URL(string: "https://admin-cp.rimashaar.com/api/v1/verify-code?lang=en") else { return }

        let body: [String: Any] = [
            "otp": code,
            "user_id": "\(userId)"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            showAlert("Failed to encode OTP.")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self.showAlert("No data from server.")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("OTP Response: \(json)")
                        if let status = json["status"] as? Int, status == 200 {
                            self.showSuccess()
                        } else {
                            let message = json["message"] as? String ?? "Invalid OTP."
                            self.showAlert(message)
                        }
                    }
                } catch {
                    self.showAlert("Unable to parse server response.")
                }
            }
        }
        task.resume()
    }
    
    // Show Alert or Success
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
        clearOTPFields()
    }
    
    func showSuccess() {
        let alert = UIAlertController(title: "Success", message: "OTP verified successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            // Navigate to next screen or dismiss
            self.navigationController?.popToRootViewController(animated: true)
        })
        self.present(alert, animated: true)
        clearOTPFields() 
    }
}
