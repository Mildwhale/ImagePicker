import UIKit

import Photos

// MARK: - ImagePickerConfiguration
struct ImagePickerConfiguration {
    enum Album: CaseIterable {
        case smart
        case userCreated
        case favorite
    }
    
    enum Sort {
        case ascending
        case descending
    }
    
    struct Theme {
        struct NavigationBar {
            let translucent: Bool
            let barTintColor: UIColor
            let itemsTintColor: UIColor
            
            init(translucent: Bool = true,
                 backgroundColor: UIColor = .systemBlue,
                 itemsTintColor: UIColor = .systemBlue) {
                self.translucent = translucent
                self.barTintColor = backgroundColor
                self.itemsTintColor = itemsTintColor
            }
        }
        
        struct Grid {
            let backgroundColor: UIColor
            
            init(backgroundColor: UIColor = .white) {
                self.backgroundColor = backgroundColor
            }
        }
        
        let navigationBar: NavigationBar
        let grid: Grid
        
        init(navigationBar: NavigationBar = NavigationBar(), grid: Grid = Grid()) {
            self.navigationBar = navigationBar
            self.grid = grid
        }
    }
    
    struct Grid {
        let numberOfItemsPerLine: Int
        let minimumItemSpacing: CGFloat
        let minimumLineSpacing: CGFloat
        
        init(numberOfItemsPerLine: Int = 3,
             minimumItemSpacing: CGFloat = 2,
             minimumLineSpacing: CGFloat = 2) {
            self.numberOfItemsPerLine = numberOfItemsPerLine
            self.minimumItemSpacing = minimumItemSpacing
            self.minimumLineSpacing = minimumLineSpacing
        }
    }
    
    struct Selection {
        let min: Int
        let max: Int
        
        init(min: Int = 1, max: Int = Int.max) {
            self.min = min
            self.max = max
        }
    }
    
    let albums: [Album]
    let sort: Sort
    let theme: Theme
    let grid: Grid
    let selection: Selection
    
    init(albums: [Album] = [],
         sort: Sort = .ascending,
         theme: Theme = Theme(),
         grid: Grid = Grid(),
         selection: Selection = Selection()) {
        self.albums = albums
        self.sort = sort
        self.theme = theme
        self.grid = grid
        self.selection = selection
    }
}

// MARK: - Convenience
extension ImagePickerConfiguration {
    static var `default`: ImagePickerConfiguration {
        return ImagePickerConfiguration()
    }
}

extension ImagePickerConfiguration.Album {
    var collections: PHFetchResult<PHAssetCollection> {
        switch self {
        case .smart:
            return PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                           subtype: .smartAlbumUserLibrary,
                                                           options:  nil)
        case .userCreated:
            return PHAssetCollection.fetchAssetCollections(with: .album,
                                                           subtype: .albumRegular,
                                                           options: nil)
            
        case .favorite:
            return PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                           subtype: .smartAlbumFavorites,
                                                           options: nil)
        }
    }
}
