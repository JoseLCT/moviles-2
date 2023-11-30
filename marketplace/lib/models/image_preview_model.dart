import 'package:image_picker/image_picker.dart';
import 'package:marketplace/models/product_image_model.dart';

class ImagePreview {
  int type;
  XFile? file;
  ProductImage? productImage;

  ImagePreview({
    required this.type,
    this.file,
    this.productImage,
  });
}
