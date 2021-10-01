//
//  ViewController.swift
//  EncryptedFileUpload
//
//  Created by Adsum MAC 1 on 30/09/21.
//

import UIKit
import FirebaseFirestore
var userID = UserDefaults.standard.integer(forKey: "userID")
class ViewController: UIViewController {

    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var lbl: UILabel!
    
    //0=upload
    //1=select
    //2=get
    var encryptedStr = ""
    var isBtnUpload = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var id = 0
        var maxid = 0
        if userID == 0{
            Firestore.firestore().collection("EncryptedImage").getDocuments { snapShot, error in
                guard error == nil else{
                    print(error?.localizedDescription as Any)
                    return
                }
                guard let docs = snapShot?.documents else{
                    return
                }
                
                for doc in docs{
                    let data = doc.data()
                    id = (data["id"] as? Int) ?? 0
                    
                    if id > maxid{
                        maxid = id
                    }
                    
                    
                    userID = maxid + 1
                    if docs.last == doc{
                        UserDefaults.standard.set(userID, forKey: "userID")
                        let uploadData = ["id":userID,"name":UIDevice.current.name,"model":UIDevice.current.model,"imageData":""] as [String : Any]
                        Firestore.firestore().collection("EncryptedImage").document("\(userID)").setData(uploadData)
                    }
                }
                
                if docs.count == 0{
                    userID = 1
                    UserDefaults.standard.set(userID, forKey: "userID")
                    let uploadData = ["id":userID,"name":UIDevice.current.name,"model":UIDevice.current.model,"imageData":""] as [String : Any]
                    Firestore.firestore().collection("EncryptedImage").document("\(userID)").setData(uploadData)
                }
            }
        }

       
        
        if isBtnUpload == 0{
            btn.setTitle("Upload", for: .normal)
        }else if isBtnUpload == 1{
            lbl.text = "Select any image to upload it..."
            btn.setTitle("Select Image", for: .normal)
        }else if isBtnUpload == 2{
            btn.setTitle("Get Image", for: .normal)
        }
    }

    @IBAction func btnClicked(_ sender: UIButton) {
        if isBtnUpload == 0{
            lbl.text = "Image Uploading..."
            uploadImage()
        }else if isBtnUpload == 1{
            presentPhotoActionSheet()
        }else if isBtnUpload == 2{
            getImageStringFromFirebase()
        }
    }
    
    func uploadImage(){
        print("Upload")
        
        DispatchQueue.main.async { [self] in
            let imgData = img.image?.jpegData(compressionQuality: 0.001)
            encryptedStr = imgData?.base64EncodedString() ?? ""
           print(encryptedStr)
        
            let uploadData = ["imageData":encryptedStr] as [String : Any]
            Firestore.firestore().collection("EncryptedImage").document("\(userID)").updateData(uploadData)
            img.image = nil
            isBtnUpload = 2
           
            
            
            if isBtnUpload == 0{
                btn.setTitle("Upload", for: .normal)
            }else if isBtnUpload == 1{
                lbl.text = "Select any image to upload it..."
                btn.setTitle("Select Image", for: .normal)
            }else if isBtnUpload == 2{
                lbl.text = "Image Uploaded"
                btn.setTitle("Get Image", for: .normal)
            }
        }
    }
    
    func getImageStringFromFirebase(){
        lbl.text = "Image fetching from firebase..."
        
        Firestore.firestore().collection("EncryptedImage").document("\(userID)").getDocument { snapshot, error in
            guard error == nil else{
                print(error?.localizedDescription as Any)
                return
            }
            let data = snapshot?.data()
            let imgData = data?["imageData"] as? String
            let imgDa = Data(base64Encoded: imgData ?? "")
            self.img.image = UIImage(data: imgDa ?? Data())
            self.lbl.text = "Image fetched"
        }
       
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentCamera()
                                                
                                            }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                
                                                self?.presentPhotoPicker()
                                                
                                            }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        isBtnUpload = 0
        btn.setTitle("Upload", for: .normal)
        self.img.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}
