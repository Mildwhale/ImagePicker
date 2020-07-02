import UIKit
import Photos

protocol ImagePickerViewControllerDelegate: class {
    func didFinishSelect(assets: [PHAsset])
}

final class ImagePickerViewController: UINavigationController {
    private let cancelButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                    target: self,
                                                                    action: #selector(cancelButtonTouchUpInside(_:)))
    private let doneButtonItem: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                  target: self,
                                                                  action: #selector(doneButtonTouchUpInside(_:)))
    
    private var selectedAssets: [PHAsset] = [] {
        didSet {
            doneButtonItem.isEnabled = selectedAssets.isEmpty == false
            
            print(#function, selectedAssets)
        }
    }

    weak var imagePickerDelegate: ImagePickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setup()
    }
    
    private func setup() {
        // NavigationItem
        doneButtonItem.isEnabled = false
        
        // GridViewController
        let allPhotos = PHAsset.fetchAssets(with: PHFetchOptions.allPhotosOptions)
        
        let gridViewController = PhotoGridViewController(fetchResult: allPhotos)
        gridViewController.delegate = self
        gridViewController.navigationItem.leftBarButtonItem = cancelButtonItem
        gridViewController.navigationItem.rightBarButtonItem = doneButtonItem
        
        viewControllers = [gridViewController]
    }
}

// MARK: - BarButtonItem Actions
extension ImagePickerViewController {
    @objc fileprivate func cancelButtonTouchUpInside(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func doneButtonTouchUpInside(_ sender: UIBarButtonItem) {
        let assets = selectedAssets
        
        // TODO: Delegate 호출 타이밍 확인
        
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.imagePickerDelegate?.didFinishSelect(assets: assets)
        }
    }
}

// MARK: - PhotoGridViewControllerDelegate
extension ImagePickerViewController: PhotoGridViewControllerDelegate {
    func didSelectAsset(_ asset: PHAsset) {
        print(#function, asset)
        selectedAssets.append(asset)
    }
    
    func didDeselectAsset(_ asset: PHAsset) {
        print(#function, asset)
        selectedAssets.removeAll(where: { $0 == asset })
    }
}

// MARK: - Convenience PHFetchOptions
private extension PHFetchOptions {
    static var allPhotosOptions: PHFetchOptions {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return allPhotosOptions
    }
}
