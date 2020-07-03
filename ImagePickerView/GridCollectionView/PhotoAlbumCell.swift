import UIKit

import SnapKit

final class PhotoGridCell: UICollectionViewCell {
    var imageView: UIImageView!
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}
