import UIKit
import Photos

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func presentImagePicker(_ sender: UIButton) {
        presentImagePicker()
    }
    
    private func presentImagePicker() {
        let viewController = ImagePickerViewController()
        viewController.imagePickerDelegate = self
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: ImagePickerViewControllerDelegate {
    func didFinishSelect(assets: [PHAsset]) {
        
    }
}
