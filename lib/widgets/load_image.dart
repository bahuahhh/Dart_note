import 'package:cached_network_image/cached_network_image.dart';
import 'package:estore_app/utils/image_utils.dart';
import 'package:estore_app/utils/string_utils.dart';
import 'package:flutter/material.dart';

/// 加载图片（支持本地与网络图片）
class LoadImage extends StatelessWidget {
  const LoadImage(this.image, {Key key, this.width, this.height, this.fit: BoxFit.cover, this.format: "png", this.holderImg: "none"}) : super(key: key);

  final String image;
  final double width;
  final double height;
  final BoxFit fit;
  final String format;
  final String holderImg;

  @override
  Widget build(BuildContext context) {
    if (StringUtils.isEmpty(image) || image == "null") {
      return LoadAssetImage(holderImg, height: height, width: width, fit: fit, format: format);
    } else {
      if (image.startsWith("http")) {
        RegExp reg = new RegExp(r"(.jpg|.png|.gif|.bmp|.jpeg|.webp)$");
        if (reg.hasMatch(image)) {
          return CachedNetworkImage(
            imageUrl: image,
            placeholder: (context, url) => LoadAssetImage(holderImg, height: height, width: width, fit: fit),
            errorWidget: (context, url, error) => LoadAssetImage(holderImg, height: height, width: width, fit: fit),
            width: width,
            height: height,
            fit: fit,
          );
        } else {
          return LoadAssetImage(holderImg, height: height, width: width, fit: fit, format: format);
        }
      } else {
        return LoadAssetImage(image, height: height, width: width, fit: fit, format: format);
      }
    }
  }
}

/// 加载本地资源图片
class LoadAssetImage extends StatelessWidget {
  const LoadAssetImage(this.image, {Key key, this.width, this.height, this.fit, this.format: 'png', this.color}) : super(key: key);

  final String image;
  final double width;
  final double height;
  final BoxFit fit;
  final String format;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ImageUtils.getImgPath(image, format: format),
      height: height,
      width: width,
      fit: fit,
      color: color,
    );
  }
}
