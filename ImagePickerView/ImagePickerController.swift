import UIKit
import Photos

protocol ImagePickerControllerDelegate: class {
    func picker(_ pickerViewController: ImagePickerController, didFinishPicking results: [PHAsset])
}

final class ImagePickerController: UINavigationController {
    private let cancelButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                    target: self,
                                                                    action: #selector(cancelButtonTouchUpInside(_:)))
    private let doneButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                  target: self,
                                                                  action: #selector(doneButtonTouchUpInside(_:)))
    
    private var selectedAssets: [PHAsset] = [] {
        didSet {
            doneButtonItem.isEnabled = selectedAssets.isEmpty == false
        }
    }

    weak var imagePickerDelegate: ImagePickerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setup()
    }
    
    private func setup() {
        // Setup navigation items.
        doneButtonItem.isEnabled = false
        
        // Setup grid view controller.
        var fetchResult: PHFetchResult<PHAsset> {
            let genericCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                             subtype: .smartAlbumGeneric,
                                                                             options: nil)
            if let allPhotosAlbum = genericCollections.firstObject {
                return PHAsset.fetchAssets(in: allPhotosAlbum, options: nil)
            } else {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                return PHAsset.fetchAssets(with: allPhotosOptions)
            }
        }
        
        let gridViewController = PhotoGridViewController(fetchResult: fetchResult)
        gridViewController.delegate = self
        gridViewController.navigationItem.leftBarButtonItem = cancelButtonItem
        gridViewController.navigationItem.rightBarButtonItem = doneButtonItem
        
        viewControllers = [gridViewController]
    }
}

// MARK: - BarButtonItem Actions
extension ImagePickerController {
    @objc func cancelButtonTouchUpInside(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTouchUpInside(_ sender: UIBarButtonItem) {
        let assets = selectedAssets
        
        // TODO: Delegate 호출 타이밍 확인
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.imagePickerDelegate?.picker(self, didFinishPicking: assets)
        }
    }
}

// MARK: - PhotoGridViewControllerDelegate
extension ImagePickerController: PhotoGridViewControllerDelegate {
    func didSelectAsset(_ asset: PHAsset) {
        selectedAssets.append(asset)
    }
    
    func didDeselectAsset(_ asset: PHAsset) {
        selectedAssets.removeAll(where: { $0 == asset })
    }
}

// MARK: - ImagePickerPresentable
protocol ImagePickerPresentable {
    func presentImagePickerController(delegate: ImagePickerControllerDelegate?, presentationStyle: UIModalPresentationStyle)
}

extension ImagePickerPresentable where Self: UIViewController {
    func presentImagePickerController(delegate: ImagePickerControllerDelegate?, presentationStyle: UIModalPresentationStyle = .fullScreen) {
        let viewController = ImagePickerController()
        viewController.imagePickerDelegate = delegate
        viewController.modalPresentationStyle = presentationStyle
        present(viewController, animated: true, completion: nil)
    }
}
