//
//  ImageTableViewCell.swift
//  PhotoAlbumSample
//
//  Created by Kyujin Kim on 2020/07/03.
//  Copyright © 2020 Kyujin Kim. All rights reserved.
//

import UIKit

final class ImageTableViewCell: UITableViewCell {
    @IBOutlet weak var centerdImageView: UIImageView!
    
    var representedAssetIdentifier: String = ""
}
