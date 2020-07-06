import UIKit

final class GridCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let checkBoxImageView = UIImageView(image: UIImage(imageLiteralResourceName: "generalCheckbox24N"))
    
    var assetIdentifier: String = ""
    
    override var isSelected: Bool {
        didSet {
            checkBoxImageView.image = isSelected ? UIImage(imageLiteralResourceName: "generalCheckboxPk24P") : UIImage(imageLiteralResourceName: "generalCheckbox24N")
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
        
        // Content image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // CheckBox image view
        addSubview(checkBoxImageView)
        
        checkBoxImageView.translatesAutoresizingMaskIntoConstraints = false
        checkBoxImageView.topAnchor.constraint(equalTo: topAnchor, constant: 8.0).isActive = true
        checkBoxImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8.0).isActive = true
    }
}

extension GridCollectionViewCell {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
