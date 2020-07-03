import UIKit

final class GridCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    var assetIdentifier: String = ""
    
    override var isSelected: Bool {
        didSet {
            alpha = isSelected ? 0.5 : 1.0
        }
    }
    
    var thumbnailImage: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    private func setup() {
        addSubview(imageView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

extension GridCollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
