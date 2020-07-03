import UIKit
import Photos

import SnapKit

protocol PhotoGridViewControllerDelegate: class {
    func didSelectAsset(_ asset: PHAsset)
    func didDeselectAsset(_ asset: PHAsset)
}

final class PhotoGridViewController: UICollectionViewController {
    public weak var delegate: PhotoGridViewControllerDelegate?
    
    private let collectionViewFlowLayout = UICollectionViewFlowLayout()
    private let imageManager = PHCachingImageManager()
    
    private var availableWidth = CGFloat(0)
    private var thumbnailSize = CGSize.zero
    private var previousPreheatRect = CGRect.zero
    
    public var fetchResult: PHFetchResult<PHAsset> = PHFetchResult() {
        didSet {
            collectionView.reloadData()
        }
    }
    private let configuration: ImagePickerConfiguration
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    init(fetchResult: PHFetchResult<PHAsset>, configuration: ImagePickerConfiguration) {
        self.fetchResult = fetchResult
        self.configuration = configuration
        super.init(collectionViewLayout: self.collectionViewFlowLayout)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetCachedAssets()
        setup()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateFlowLayoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let scale = UIScreen.main.scale
        let cellSize = collectionViewFlowLayout.itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    private func setup() {
        collectionView.allowsMultipleSelection = true
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: PhotoGridCell.reuseIdentifier)
        
        // Theme
        collectionView.backgroundColor = configuration.theme.grid.backgroundColor
        
        // Grid
        collectionViewFlowLayout.minimumInteritemSpacing = configuration.grid.minimumItemSpacing
        collectionViewFlowLayout.minimumLineSpacing = configuration.grid.minimumLineSpacing
        
        // Register
        PHPhotoLibrary.shared().register(self)
    }
    
    private func updateFlowLayoutIfNeeded() {
        let width = view.bounds.inset(by: view.safeAreaInsets).width
        
        if availableWidth != width {
            availableWidth = width
            
            let numberOfItemsPerLine = CGFloat(configuration.grid.numberOfItemsPerLine)
            let itemsWidth = availableWidth - (configuration.grid.minimumItemSpacing * (numberOfItemsPerLine - 1))
            let itemWidth = (itemsWidth / numberOfItemsPerLine).rounded(.towardZero)
            collectionViewFlowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)

            let actualItemSpacing = (availableWidth - (itemWidth * numberOfItemsPerLine)) / (numberOfItemsPerLine - 1)
            collectionViewFlowLayout.minimumInteritemSpacing = actualItemSpacing
            collectionViewFlowLayout.minimumLineSpacing = actualItemSpacing
        }
    }
}

// MARK: - UICollectionViewDataSource
extension PhotoGridViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridCell.reuseIdentifier, for: indexPath)
        
        if let gridCell = cell as? PhotoGridCell {
            let asset = fetchResult.object(at: indexPath.item)
            gridCell.representedAssetIdentifier = asset.localIdentifier
            
            imageManager.requestImage(for: asset,
                                      targetSize: thumbnailSize,
                                      contentMode: .aspectFill,
                                      options: PHImageRequestOptions.thumbnail,
                                      resultHandler: { image, _ in
                                        if gridCell.representedAssetIdentifier == asset.localIdentifier {
                                            gridCell.thumbnailImage = image
                                        }
            })
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension PhotoGridViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return true }
        return selectedItems.count < configuration.selection.max
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectAsset(fetchResult.object(at: indexPath.item))
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.didDeselectAsset(fetchResult.object(at: indexPath.item))
    }
}

// MARK: - UIScrollViewDelegate
extension PhotoGridViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

// MARK: - Caching
extension PhotoGridViewController {
    private func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension PhotoGridViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.sync {
            if let changeDetails = changeInstance.changeDetails(for: fetchResult) {
                fetchResult = changeDetails.fetchResultAfterChanges
            }
        }
    }
}

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

private extension PHImageRequestOptions {
    static var thumbnail: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        return options
    }
}
