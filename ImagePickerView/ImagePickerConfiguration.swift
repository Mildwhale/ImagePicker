import UIKit

// MARK: - ImagePickerConfiguration
struct ImagePickerConfiguration {
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
    
    let theme: Theme
    let grid: Grid
    let selection: Selection
    
    init(theme: Theme = Theme(),
         grid: Grid = Grid(),
         selection: Selection = Selection()) {
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
