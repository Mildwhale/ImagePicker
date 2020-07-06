import UIKit
import Photos

protocol ImagePickerControllerDelegate: class {
    func picker(_ pickerViewController: ImagePickerController, didFinishPicking results: [PHAsset])
}

final class ImagePickerController: UINavigationController {
    // Delegate
    public weak var imagePickerDelegate: ImagePickerControllerDelegate?
    
    // UI Components
    private var collectionViewController: GridCollectionViewController?
    private let albumButton = UIButton(type: .system)
    private let cancelButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                   target: self,
                                                   action: #selector(cancelButtonTouchUpInside(_:)))
    private let doneButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                 target: self,
                                                 action: #selector(doneButtonTouchUpInside(_:)))
    
    // Datas
    private var pickedAssets: [PHAsset] = [] {
        didSet { updateUI() }
    }
    
    private var selectedAlbumIndex: Int = 0 {
        didSet { updateUI() }
    }
    
    private lazy var albums: [PHAssetCollection] = {
        var albums: [PHAssetCollection] = []
        configuration.albums.forEach {
            $0.collections.enumerateObjects { [weak self] (collection, _, _) in
                guard let self = self else { return }
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                fetchOptions.fetchLimit = 1
                
                guard PHAsset.fetchAssets(in: collection, options: fetchOptions).count > 0 else { return }
                albums.append(collection)
            }
        }
        return albums
    }()
    private let configuration: ImagePickerConfiguration
    
    // Init
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
        albumButton.addTarget(self, action: #selector(presentAlbumSelectionSheet(_:)), for: .touchUpInside)
        
        // Setup CollectionViewController
        let fetchResult = fetchAssets(from: albums.first)
        let collectionViewController = GridCollectionViewController(fetchResult: fetchResult, configuration: configuration)
        collectionViewController.delegate = self
        collectionViewController.navigationItem.leftBarButtonItem = cancelButtonItem
        collectionViewController.navigationItem.rightBarButtonItem = doneButtonItem

        viewControllers = [collectionViewController]
        
        self.collectionViewController = collectionViewController
    }
    
    private func updateUI() {
        doneButtonItem.isEnabled = pickedAssets.count >= configuration.selection.min

        collectionViewController?.navigationItem.titleView = albums.count > 1 ? albumButton : nil
        
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
    
    @objc func presentAlbumSelectionSheet(_ sender: UIButton) {
        guard albums.isEmpty == false else { return }
        
        let sheet = UIAlertController(title: "앨범 선택", message: nil, preferredStyle: .actionSheet)
        albums.enumerated().forEach { (index, album) in
            let action = UIAlertAction(title: album.localizedTitle, style: .default) { [weak self] action in
                guard let self = self else { return }
                if index < self.albums.count {
                    self.collectionViewController?.fetchResult = self.fetchAssets(from: self.albums[index])
                    self.selectedAlbumIndex = index
                    self.pickedAssets.removeAll()
                }
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(sheet, animated: true, completion: nil)
    }
}

// MARK: - Asset & Album Handler
extension ImagePickerController {
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
extension ImagePickerController: GridCollectionViewControllerDelegate {
    func collectionView(_ controller: GridCollectionViewController, didSelect asset: PHAsset) {
        pickedAssets.append(asset)
    }
    
    func collectionView(_ controller: GridCollectionViewController, didDeselect asset: PHAsset) {
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
