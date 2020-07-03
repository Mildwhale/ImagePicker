import UIKit
import Photos

protocol ImagePickerControllerDelegate: class {
    func picker(_ pickerViewController: ImagePickerController, didFinishPicking results: [PHAsset])
}

final class ImagePickerController: UINavigationController {
    public weak var imagePickerDelegate: ImagePickerControllerDelegate?
    
    private var gridViewController: PhotoGridViewController!
    private let albumButton = UIButton(type: .system)
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
    
    private var albums: [PHAssetCollection] = []
    private var selectedAlbumIndex: Int = 0 {
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
        // Setup NavigationBar & Items
        navigationBar.isTranslucent = configuration.theme.navigationBar.translucent
        navigationBar.barTintColor = configuration.theme.navigationBar.barTintColor
        cancelButtonItem.tintColor = configuration.theme.navigationBar.itemsTintColor
        doneButtonItem.tintColor = configuration.theme.navigationBar.itemsTintColor
        
        // Album Button
        albumButton.addTarget(self, action: #selector(presentAlbumChoiceSheet(_:)), for: .touchUpInside)
        
        // Filter Albums
        filterEmptyAlbum()
        
        // Setup GridViewController.
        let fetchResult: PHFetchResult<PHAsset> = fetchAssets(from: albums.first)
        let gridViewController = PhotoGridViewController(fetchResult: fetchResult, configuration: configuration)
        gridViewController.delegate = self
        gridViewController.navigationItem.titleView = albumButton
        gridViewController.navigationItem.leftBarButtonItem = cancelButtonItem
        gridViewController.navigationItem.rightBarButtonItem = doneButtonItem

        viewControllers = [gridViewController]
        
        self.gridViewController = gridViewController
    }
    
    private func fetchAssets(from collection: PHAssetCollection? = nil) -> PHFetchResult<PHAsset> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: configuration.sort == .ascending)]
        
        if let collection = collection {
            return PHAsset.fetchAssets(in: collection, options: fetchOptions)
        } else {
            return PHAsset.fetchAssets(with: fetchOptions)
        }
    }
    
    private func filterEmptyAlbum() {
        configuration.albums.forEach {
            $0.collections.enumerateObjects(options: .concurrent) { [weak self] (collection, _, _) in
                guard let self = self else { return }
                let fetchOptions = PHFetchOptions()
                fetchOptions.fetchLimit = 1
                
                if PHAsset.fetchAssets(in: collection, options: fetchOptions).count > 0 {
                    self.albums.append(collection)
                }
            }
        }
    }
    
    private func updateUI() {
        doneButtonItem.isEnabled = pickedAssets.count >= configuration.selection.min
        
        var albumButtonTitle: String? {
            if albums.isEmpty {
                return "All"
            } else if selectedAlbumIndex < albums.count {
                let album = albums[selectedAlbumIndex]
                return album.localizedTitle
            } else {
                return nil
            }
        }
        albumButton.setTitle(albumButtonTitle, for: .normal)
    }
    
    @objc func presentAlbumChoiceSheet(_ sender: UIButton) {
        guard albums.isEmpty == false else { return }
        
        let sheet = UIAlertController(title: "앨범 선택", message: nil, preferredStyle: .actionSheet)
        albums.enumerated().forEach { (index, album) in
            let action = UIAlertAction(title: album.localizedTitle, style: .default) { [weak self] action in
                guard let self = self else { return }
                if index < self.albums.count {
                    self.gridViewController.fetchResult = self.fetchAssets(from: self.albums[index])
                    self.selectedAlbumIndex = index
                    self.pickedAssets.removeAll()
                }
            }
            sheet.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(cancelAction)
        present(sheet, animated: true, completion: nil)
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
