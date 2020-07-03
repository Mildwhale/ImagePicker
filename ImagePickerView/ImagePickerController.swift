import UIKit
import Photos

protocol ImagePickerControllerDelegate: class {
    func picker(_ pickerViewController: ImagePickerController, didFinishPicking results: [PHAsset])
}

final class ImagePickerController: UINavigationController {
    public weak var imagePickerDelegate: ImagePickerControllerDelegate?
    
    private let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                   target: self,
                                                   action: #selector(cancelButtonTouchUpInside(_:)))
    private let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                 target: self,
                                                 action: #selector(doneButtonTouchUpInside(_:)))
    
    private var pickedAssets: [PHAsset] = [] {
        didSet {
            updateUI()
        }
    }
    
    private let configuration: ImagePickerConfiguration
    
    init(configuration: ImagePickerConfiguration = .default) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        updateUI()
    }
    
    private func setup() {
        // Setup NavigationBar
        navigationBar.isTranslucent = configuration.theme.navigationBar.translucent
        navigationBar.barTintColor = configuration.theme.navigationBar.barTintColor
        cancelButtonItem.tintColor = configuration.theme.navigationBar.itemsTintColor
        doneButtonItem.tintColor = configuration.theme.navigationBar.itemsTintColor
        
        // Setup GridViewController.
        var fetchResult: PHFetchResult<PHAsset> {
            let genericCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                             subtype: .smartAlbumGeneric,
                                                                             options: nil)
            if let allPhotosAlbum = genericCollections.firstObject {
                return PHAsset.fetchAssets(in: allPhotosAlbum, options: nil)
            } else {
                let allPhotosOptions = PHFetchOptions()
                allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                return PHAsset.fetchAssets(with: allPhotosOptions)
            }
        }
        
        let gridViewController = PhotoGridViewController(fetchResult: fetchResult, configuration: configuration)
        gridViewController.delegate = self
        gridViewController.navigationItem.leftBarButtonItem = cancelButtonItem
        gridViewController.navigationItem.rightBarButtonItem = doneButtonItem
        
        viewControllers = [gridViewController]
    }
    
    private func updateUI() {
        doneButtonItem.isEnabled = pickedAssets.count >= configuration.selection.min
    }
}

// MARK: - BarButtonItem Actions
extension ImagePickerController {
    @objc func cancelButtonTouchUpInside(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonTouchUpInside(_ sender: UIBarButtonItem) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.imagePickerDelegate?.picker(self, didFinishPicking: self.pickedAssets)
        }
    }
}

// MARK: - PhotoGridViewControllerDelegate
extension ImagePickerController: PhotoGridViewControllerDelegate {
    func didSelectAsset(_ asset: PHAsset) {
        pickedAssets.append(asset)
    }
    
    func didDeselectAsset(_ asset: PHAsset) {
        pickedAssets.removeAll(where: { $0 == asset })
    }
}

// MARK: - ImagePickerPresentable
protocol ImagePickerPresentable {
    func presentImagePickerController(configuration: ImagePickerConfiguration,
                                      delegate: ImagePickerControllerDelegate?,
                                      presentationStyle: UIModalPresentationStyle)
}

extension ImagePickerPresentable where Self: UIViewController {
    func presentImagePickerController(configuration: ImagePickerConfiguration = .default,
                                      delegate: ImagePickerControllerDelegate? = nil,
                                      presentationStyle: UIModalPresentationStyle = .fullScreen) {
        let pickerController = ImagePickerController(configuration: configuration)
        pickerController.imagePickerDelegate = delegate
        pickerController.modalPresentationStyle = presentationStyle
        present(pickerController, animated: true, completion: nil)
    }
}
