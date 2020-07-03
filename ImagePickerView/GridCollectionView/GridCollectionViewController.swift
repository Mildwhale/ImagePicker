import UIKit
import Photos

protocol GridCollectionViewControllerDelegate: class {
    func collectionView(_ controller: GridCollectionViewController, didSelect asset: PHAsset)
    func collectionView(_ controller: GridCollectionViewController, didDeselect asset: PHAsset)
}

final class GridCollectionViewController: UICollectionViewController {
    // Delegate
    public weak var delegate: GridCollectionViewControllerDelegate?

    // Thumbnail Caching
    private let imageManager = PHCachingImageManager()
    
    // Layout Attributes
    private let collectionViewFlowLayout = UICollectionViewFlowLayout()
    
    private var availableWidth = CGFloat(0)
    private var thumbnailSize = CGSize.zero
    private var previousPreheatRect = CGRect.zero
    
    // DataSource
    public var fetchResult: PHFetchResult<PHAsset> {
        get {
            return _fetchResult
        }
        set {
            _fetchResult = newValue
            collectionView.reloadData()
        }
    }
    private var _fetchResult: PHFetchResult<PHAsset>
    
    // Configuration
    private let configuration: ImagePickerConfiguration
    
    // Init
    deinit {
        imageManager.stopCachingImagesForAllAssets()
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    init(fetchResult: PHFetchResult<PHAsset>, configuration: ImagePickerConfiguration) {
        self._fetchResult = fetchResult
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    private func setup() {
        collectionView.backgroundColor = .white
        collectionView.allowsMultipleSelection = true
        collectionView.register(GridCollectionViewCell.self, forCellWithReuseIdentifier: GridCollectionViewCell.reuseIdentifier)
        
        // Register change observer
        PHPhotoLibrary.shared().register(self)
    }
    
    private func updateFlowLayoutIfNeeded() {
        let width = view.bounds.inset(by: view.safeAreaInsets).width
        
        if availableWidth != width {
            availableWidth = width
            
            let numberOfItemsPerLine = CGFloat(configuration.grid.numberOfItemsPerLine)
            let itemsWidth = availableWidth - (configuration.grid.estimateItemSpacing * (numberOfItemsPerLine - 1))
            let itemWidth = (itemsWidth / numberOfItemsPerLine).rounded(.towardZero)
            let cellSize = CGSize(width: itemWidth, height: itemWidth)
            collectionViewFlowLayout.itemSize = cellSize

            let actualItemSpacing = (availableWidth - (itemWidth * numberOfItemsPerLine)) / (numberOfItemsPerLine - 1)
            collectionViewFlowLayout.minimumInteritemSpacing = actualItemSpacing
            collectionViewFlowLayout.minimumLineSpacing = actualItemSpacing
            
            let scale = UIScreen.main.scale
            thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension GridCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GridCollectionViewCell.reuseIdentifier, for: indexPath)
        
        if let gridCell = cell as? GridCollectionViewCell {
            let asset = fetchResult.object(at: indexPath.item)
            gridCell.assetIdentifier = asset.localIdentifier
            
            imageManager.requestImage(for: asset,
                                      targetSize: thumbnailSize,
                                      contentMode: .aspectFill,
                                      options: PHImageRequestOptions.thumbnail,
                                      resultHandler: { image, _ in
                                        if gridCell.assetIdentifier == asset.localIdentifier {
                                            gridCell.thumbnailImage = image
                                        }
            })
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GridCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let selectedItems = collectionView.indexPathsForSelectedItems else { return true }
        return selectedItems.count < configuration.selection.max
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.collectionView(self, didSelect: fetchResult.object(at: indexPath.item))
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.collectionView(self, didDeselect: fetchResult.object(at: indexPath.item))
    }
}

// MARK: - UIScrollViewDelegate
extension GridCollectionViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

// MARK: - Caching
extension GridCollectionViewController {
    private func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
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
extension GridCollectionViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
        
        DispatchQueue.main.sync {
            _fetchResult = changes.fetchResultAfterChanges
            
            if changes.hasIncrementalChanges {
                guard let collectionView = self.collectionView else { fatalError() }
                
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                }
            } else {
                collectionView.reloadData()
            }
            resetCachedAssets()
        }
    }
}

// MARK: - Convenience Extensions
private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) else { return [] }
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
