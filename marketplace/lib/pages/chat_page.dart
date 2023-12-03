import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/map_data_model.dart';
import 'package:marketplace/models/message_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/services/chat_service.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final LocalStorage storage = LocalStorage('marketplace_app');
  final String apiUrl = dotenv.get('API_URL');
  int id = 0;
  int productId = 0;
  int userId = 0;
  Product? product;
  Future<List<Message>>? messages;
  TextEditingController messageController = TextEditingController();
  final String mapsApiKey = dotenv.get('GOOGLE_MAPS_API_KEY');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    id = arguments['chatId'] ?? 0;
    productId = arguments['productId'] ?? 0;
    userId = arguments['userId'] ?? 0;
    if (id != 0) {
      _loadMessages();
    }
    if (productId != 0) {
      getProduct(productId).then((value) {
        setState(() {
          product = value;
        });
      });
    }
  }

  void _loadMessages() async {
    String token = storage.getItem('token');

    messages = getMessagesByChat(id, token);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        surfaceTintColor: Colors.grey.shade900,
        title: Row(
          children: [
            getProductImage(),
            const SizedBox(width: 10),
            Text(product?.name ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.grey.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          getSubHeader(),
          Expanded(
            child: FutureBuilder(
                future: messages,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        return getMessageView(snapshot.data?[index]);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
          ),
          getBottomBar(),
        ],
      ),
    );
  }

  Widget getProductImage() {
    if (product == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey,
        highlightColor: Colors.grey.shade800,
        child: SizedBox(
          width: 25,
          height: 25,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(50))),
        ),
      );
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: product!.productimages != null &&
                product!.productimages!.isNotEmpty
            ? Image.network(apiUrl + product!.productimages![0].url,
                fit: BoxFit.cover,
                width: 25,
                height: 25, loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade700,
                  child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(50))),
                );
              })
            : Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(25)),
                child: const Icon(Icons.image, color: Colors.grey, size: 16),
              ));
  }

  Widget getSubHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
      ),
      child: Column(children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.store, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
                product?.price == 0
                    ? 'Gratis - ${product?.name}'
                    : 'Bs. ${product?.price.toString()} - ${product?.name}',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ver producto',
                      style: TextStyle(color: Colors.white))),
            ),
            if (userId == product?.userId) ...[
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Vendido',
                        style: TextStyle(color: Colors.white))),
              ),
            ],
          ],
        ),
      ]),
    );
  }

  Widget getMessageView(Message? message) {
    if (message == null) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: message.userIdSender == userId
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (message.type == 1) getTextMessage(message),
          if (message.type == 2) getImageMessage(message),
          if (message.type == 3) getMapMessage(message),
        ],
      ),
    );
  }

  Widget getTextMessage(Message message) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message.message ?? '',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget getImageMessage(Message message) {
    if (message.imageUrl == null) {
      return Container(
        width: 200,
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: const Icon(Icons.image, color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: () {
        showFullScreenImage(message.imageUrl!);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            apiUrl + message.imageUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getMapMessage(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GestureDetector(
        onTap: () async {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Abriendo Google Maps...')));
          Uri url = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=${message.latitude},${message.longitude}');
          if (await canLaunchUrl(url)) {
            launchUrl(url);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            'https://maps.googleapis.com/maps/api/staticmap?'
            'center=${message.latitude},${message.longitude}&'
            'zoom=14&'
            'markers=size:mid%7Ccolor:red%7C${message.latitude},${message.longitude}&'
            'size=900x400&'
            'key=$mapsApiKey',
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget getBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: Form(
        child: Row(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: IconButton(
                icon: const Icon(Icons.add,
                    color: Color.fromARGB(255, 8, 102, 255)),
                iconSize: 36,
                padding: EdgeInsets.zero,
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      backgroundColor: Colors.grey.shade900,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) {
                        return getMessageOptionsView();
                      });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextFormField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade800,
                    hintText: 'Aa',
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 8, 102, 255),
                borderRadius: BorderRadius.circular(25),
              ),
              height: 36,
              width: 36,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                iconSize: 20,
                onPressed: () {
                  if (messageController.text.isNotEmpty) {
                    Message message = Message(
                      chatId: id,
                      message: messageController.text,
                      type: 1,
                    );
                    sendMessage(message, storage.getItem('token'));
                    messageController.clear();
                    _loadMessages();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getMessageOptionsView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            width: double.infinity,
            child: GestureDetector(
                onTap: () {
                  pickImage(1);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: Color.fromARGB(255, 8, 102, 255)),
                    SizedBox(width: 10),
                    Text('Cámara',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            fontSize: 18)),
                  ],
                )),
          ),
          Divider(color: Colors.grey.shade800),
          SizedBox(
              height: 48,
              width: double.infinity,
              child: GestureDetector(
                  onTap: () {
                    pickImage(2);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.photo_outlined,
                          color: Color.fromARGB(255, 8, 102, 255)),
                      SizedBox(width: 10),
                      Text('Galería',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 18)),
                    ],
                  ))),
          Divider(color: Colors.grey.shade800),
          SizedBox(
              height: 48,
              width: double.infinity,
              child: GestureDetector(
                  onTap: () {
                    storage.setItem('mapMode', 'chat');
                    Navigator.pushNamed(context, '/maps').then((value) {
                      if (value != null && value is MapData) {
                        Message message = Message(
                          chatId: id,
                          latitude: value.latitude,
                          longitude: value.longitude,
                          type: 3,
                        );
                        sendMessage(message, storage.getItem('token'));
                        _loadMessages();
                      }
                    });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: Color.fromARGB(255, 8, 102, 255)),
                      SizedBox(width: 10),
                      Text('Ubicación',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 18)),
                    ],
                  ))),
        ],
      ),
    );
  }

  Future<void> pickImage(int type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: type == 1 ? ImageSource.camera : ImageSource.gallery);
    if (image == null) {
      return;
    }
    Message message = Message(
      chatId: id,
      imageUrl: image.path,
      type: 2,
    );
    sendMessage(message, storage.getItem('token'));
  }

  Future<void> showFullScreenImage(String url) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: SizedBox.expand(
            child: Image.network(
              apiUrl + url,
              width: MediaQuery.of(context).size.width,
            ),
          ),
        );
      },
    );
  }
}
