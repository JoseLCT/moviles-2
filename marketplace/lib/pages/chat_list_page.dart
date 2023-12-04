import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/chat_model.dart';
import 'package:marketplace/models/message_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/models/user_model.dart';
import 'package:marketplace/services/chat_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final LocalStorage storage = LocalStorage('marketplace_app');
  final String apiUrl = dotenv.get('API_URL');
  late IO.Socket socket;
  Future<List<Chat>>? chats;
  Product? product;
  User? user;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    String token = storage.getItem('token');
    product = arguments['product'];
    user = arguments['user'];
    if (product?.id != null) {
      getChatsByProduct(product?.id ?? 0, token).then((value) {
        setState(() {
          value.sort((a, b) {
            if (a.lastMessage?.createdAt == null ||
                b.lastMessage?.createdAt == null) {
              return 0;
            }
            return b.lastMessage!.createdAt!
                .compareTo(a.lastMessage!.createdAt!);
          });
          chats = Future.value(value);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          title: Text(product?.name ?? 'Chats',
              style: const TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.grey.shade900,
          leading: TextButton(
            onPressed: () {
              socket.disconnect();
              socket.dispose();
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          ),
        ),
        body: FutureBuilder(
          future: chats,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!.isEmpty
                  ? const Center(
                      child: Text('No tienes chats',
                          style: TextStyle(color: Colors.white)))
                  : ListView.builder(
                      itemCount: snapshot.data?.length ?? 0,
                      itemBuilder: (context, index) {
                        return getChatView(snapshot.data?[index]);
                      },
                    );
            } else if (snapshot.hasError) {
              return const Text('Error');
            } else {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              );
            }
          },
        ));
  }

  Widget getChatView(Chat? chat) {
    if (chat == null) {
      return const Text('Error');
    }
    String lastMessage = '';
    String userSender = '';
    if (chat.lastMessage?.userIdSender == user?.id) {
      userSender = 'Tú:';
    }
    switch (chat.lastMessage?.type) {
      case 1:
        lastMessage += chat.lastMessage?.message ?? 'Sin mensajes';
        break;
      case 2:
        lastMessage += 'Imagen';
        break;
      case 3:
        lastMessage += 'Ubicación';
        break;
      default:
        lastMessage = 'Sin mensajes';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: GestureDetector(
        onTap: () {
          socket.disconnect();
          socket.dispose();
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'chat': chat,
              'productId': chat.productId,
              'userId': user?.id,
            },
          ).then((value) {
            initSocket();
            loadChats();
          });
        },
        child: Row(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: product?.productimages != null &&
                        product!.productimages!.isNotEmpty
                    ? Image.network(apiUrl + product!.productimages![0].url,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: MediaQuery.of(context).size.width * 0.15,
                        loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade700,
                          child: Container(
                              width: MediaQuery.of(context).size.width * 0.15,
                              height: MediaQuery.of(context).size.width * 0.15,
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade800,
                                  borderRadius: BorderRadius.circular(50))),
                        );
                      })
                    : Container(
                        width: MediaQuery.of(context).size.width * 0.15,
                        height: MediaQuery.of(context).size.width * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(25)),
                        child: const Icon(Icons.image, color: Colors.grey))),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${chat.user?.fullname ?? 'Sin nombre'} · ${chat.product?.name ?? 'Sin nombre'}',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(userSender,
                        style: const TextStyle(
                            color: Color.fromARGB(255, 228, 230, 235))),
                    if (chat.lastMessage?.type != null &&
                        chat.lastMessage?.type != 1) ...[
                      const SizedBox(width: 4),
                      Icon(
                          chat.lastMessage?.type == 2
                              ? Icons.image
                              : Icons.place,
                          color: Colors.grey.shade500,
                          size: 16),
                    ],
                    const SizedBox(width: 4),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: Text(lastMessage,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 228, 230, 235))),
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void initSocket() {
    socket = IO.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    if (socket.connected) {
      socket.emit('identificarUsuario', {'id': user?.id});
    }
    socket.connect();
    socket.onConnect((_) {
      socket.emit('identificarUsuario', {'id': user?.id});
    });
    socket.on('usuarioIdentificado', (data) {
      print(data);
    });
    socket.on('mensajeRecibido', (data) {
      Message message = Message.fromJson(data);
      String token = storage.getItem('token');
      getChatsByProduct(product?.id ?? 0, token).then((value) {
        if (!mounted) return;
        setState(() {
          loadChats();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: const Color.fromARGB(255, 18, 87, 189),
              content: Text(
                  '${message.userSender?.fullname ?? 'Sin nombre'} te ha enviado un mensaje',
                  style: const TextStyle(color: Colors.white))));
        });
      });
    });
  }

  void loadChats() {
    String token = storage.getItem('token');
    getChatsByProduct(product?.id ?? 0, token).then((value) {
      setState(() {
        value.sort((a, b) {
          if (a.lastMessage?.createdAt == null ||
              b.lastMessage?.createdAt == null) {
            return 0;
          }
          return b.lastMessage!.createdAt!.compareTo(a.lastMessage!.createdAt!);
        });
        chats = Future.value(value);
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(error.toString(),
              style: const TextStyle(color: Colors.white))));
    });
  }
}
