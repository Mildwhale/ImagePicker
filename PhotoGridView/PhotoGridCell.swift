import UIKit

import SnapKit

final class PhotoGridCell: UICollectionViewCell {
    let imageView: UIImageView = UIImageView()
    var representedAssetIdentifier: String = ""
    
    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 0.5 : 1.0
        }
    }
    
    var thumbnailImage: UIImage? {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setup() {
        addSubview(imageView)
        
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension PhotoGridCell {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
