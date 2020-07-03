import UIKit
import Photos

class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let imageManager = PHCachingImageManager()
    
    private var dataSource: [PHAsset] = [] {
        didSet { tableView.reloadData() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func presentImagePicker(_ sender: UIButton) {
        let albums: [ImagePickerConfiguration.Album] = [.smart, .userCreated, .favorite]
        let navigationBarTheme = ImagePickerConfiguration.Theme.NavigationBar(translucent: true,
                                                                              backgroundColor: .white,
                                                                              itemsTintColor: .systemPink)
        let theme = ImagePickerConfiguration.Theme(navigationBar: navigationBarTheme)
        let grid = ImagePickerConfiguration.Grid(numberOfItemsPerLine: 3,
                                                 estimateItemSpacing: 2,
                                                 estimateLineSpacing: 2)
        let selection = ImagePickerConfiguration.Selection(min: 1, max: 5)
        let configuraion = ImagePickerConfiguration(albums: albums,
                                                    sort: .descending,
                                                    theme: theme,
                                                    grid: grid,
                                                    selection: selection)
        
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            if PHPhotoLibrary.authorizationStatus() == .notDetermined {
                PHPhotoLibrary.requestAuthorization({ status in
                    if status == .authorized {
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.presentImagePickerController(configuration: configuraion, delegate: self)
                        }
                    }
                })
            } else {
                // notify to user (e.g Alert or Toast)
            }
            return
        }
        presentImagePickerController(configuration: configuraion, delegate: self)
    }
}

extension ViewController: ImagePickerPresentable {}

// MARK: - ImagePickerControllerDelegate
extension ViewController: ImagePickerControllerDelegate {
    func picker(_ pickerViewController: ImagePickerController, didFinishPicking results: [PHAsset]) {
        dataSource = results
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageTableViewCell", for: indexPath)
        let asset = dataSource[indexPath.row]
        
        if let imageCell = cell as? ImageTableViewCell {
            imageCell.representedAssetIdentifier = asset.localIdentifier
            imageManager.requestImage(for: asset,
                                      targetSize: CGSize(width: 64, height: 64),
                                      contentMode: .aspectFill,
                                      options: nil,
                                      resultHandler: { image, _ in
                                        if imageCell.representedAssetIdentifier == asset.localIdentifier {
                                            imageCell.centerdImageView.image = image
                                        }
            })
        }
        return cell
    }
}
