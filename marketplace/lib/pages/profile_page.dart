import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localstorage/localstorage.dart';
import 'package:marketplace/models/chat_model.dart';
import 'package:marketplace/models/message_model.dart';
import 'package:marketplace/models/product_model.dart';
import 'package:marketplace/models/user_model.dart';
import 'package:marketplace/services/auth_service.dart';
import 'package:marketplace/services/chat_service.dart';
import 'package:marketplace/services/product_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalStorage storage = LocalStorage('marketplace_app');
  final String apiUrl = dotenv.get('API_URL');
  Future<List<Product>>? products;
  User? _user;
  late IO.Socket socket;
  Future<List<Chat>>? chats;

  @override
  void initState() {
    super.initState();
    String token = storage.getItem('token');
    getUser(token).then((value) {
      getProductsByToken(token).then((value) {
        setState(() {
          products = Future.value(value);
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red,
            content: Text(error.toString(),
                style: const TextStyle(color: Colors.white))));
      });
      loadChats();
      setState(() {
        _user = value;
        initSocket();
      });
    }).catchError((error) {
      String errorMessage = error.toString().split(':')[1].trim();
      if (errorMessage == '401') {
        storage.clear().then((_) =>
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Sesión expirada, inicia sesión nuevamente',
                style: TextStyle(color: Colors.white))));
      }
    });
  }

  void loadChats() {
    String token = storage.getItem('token');
    getChatsByUser(token).then((value) {
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

  void initSocket() {
    socket = IO.io(apiUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    if (socket.connected) {
      socket.emit('identificarUsuario', {'id': _user?.id});
    }
    socket.connect();
    socket.onConnect((_) {
      socket.emit('identificarUsuario', {'id': _user?.id});
    });
    socket.on('usuarioIdentificado', (data) {
      print(data);
    });
    socket.on('mensajeRecibido', (data) {
      Message message = Message.fromJson(data);
      getChatsByUser(storage.getItem('token')).then((value) {
        if (!mounted) return;
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: const Color.fromARGB(255, 18, 87, 189),
              content: Text(
                  '${message.userSender?.fullname ?? 'Sin nombre'} te ha enviado un mensaje',
                  style: const TextStyle(color: Colors.white))));
        });
      });
    });
    socket.onDisconnect((_) => print('disconnect'));
    socket.on('fromServer', (_) => print(_));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          title: const Text('Perfil', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () {
              socket.disconnect();
              socket.dispose();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 54, 54, 54))),
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      backgroundColor: Colors.grey.shade900,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) {
                        return getInfoView();
                      });
                },
                icon: const Icon(Icons.settings, color: Colors.white)),
          ],
          backgroundColor: Colors.grey.shade900,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 4.0, color: Colors.white),
              insets: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            labelStyle: const TextStyle(fontSize: 16),
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'Mis productos'),
              Tab(text: 'Chats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            myProductsTab(),
            chatsTab(),
          ],
        ),
      ),
    );
  }

  Widget getInfoView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Información de la cuenta',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                  width: 190,
                  child: Text('Nombre completo',
                      style: TextStyle(color: Colors.grey.shade500))),
              Text(_user?.fullname ?? 'Sin nombre',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                  width: 190,
                  child: Text('Correo electrónico',
                      style: TextStyle(color: Colors.grey.shade500))),
              Text(_user?.email ?? 'Sin correo',
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text('Cerrar sesión',
                              style: TextStyle(color: Colors.white)),
                          content: const Text(
                              '¿Estás seguro que deseas cerrar sesión?',
                              style: TextStyle(color: Colors.white)),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancelar',
                                    style: TextStyle(color: Colors.white))),
                            TextButton(
                                onPressed: () {
                                  storage.deleteItem('token');
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/', (route) => false);
                                },
                                child: const Text('Cerrar sesión',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        );
                      });
                },
                style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Cerrar sesión',
                    style: TextStyle(color: Colors.white, fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget myProductsTab() {
    return Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, top: 18),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
                child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/product-form')
                              .then((_) {
                            String token = storage.getItem('token');
                            getProductsByToken(token).then((value) {
                              setState(() {
                                products = Future.value(value);
                              });
                            }).catchError((error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(error.toString(),
                                          style: const TextStyle(
                                              color: Colors.white))));
                            });
                          });
                        },
                        style: TextButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 8, 102, 255),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(double.infinity, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            )),
                        label: const Text('Crear publicación',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        icon: const Icon(Icons.create, color: Colors.white)))),
            getProductListView(),
          ],
        ));
  }

  Widget getProductListView() {
    return FutureBuilder<List<Product>>(
      future: products,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
            return getProductView(snapshot.data?[index]);
          }, childCount: snapshot.data?.length ?? 0));
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(child: Text('${snapshot.error}'));
        } else {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
          );
        }
      },
    );
  }

  Widget getProductView(Product? product) {
    if (product == null || product.id == 1) {
      return const Text('Error');
    }
    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/product-detail',
                arguments: {'id': product.id});
          },
          child: Row(children: [
            if (product.productimages != null &&
                product.productimages!.isNotEmpty) ...[
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(apiUrl + product.productimages![0].url,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: MediaQuery.of(context).size.width * 0.2,
                      loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: MediaQuery.of(context).size.width * 0.2,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8))),
                    );
                  })),
            ] else ...[
              Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.width * 0.2,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image, color: Colors.grey)),
            ],
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(product.name,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  Text(product.price == 0 ? 'Gratis' : 'Bs. ${product.price}',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 228, 230, 235))),
                ])),
            IconButton(
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      backgroundColor: Colors.grey.shade900,
                      barrierColor: Colors.black.withOpacity(0.5),
                      builder: (context) {
                        return getProductOptionsView(product, context);
                      });
                },
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey)),
          ]),
        ));
  }

  Widget getProductOptionsView(
      Product product, BuildContext bottomSheetContext) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              socket.disconnect();
              socket.dispose();
              Navigator.pop(bottomSheetContext);
              Navigator.pushNamed(context, '/chat-list',
                  arguments: {'user': _user, 'product': product}).then((_) {
                initSocket();
                loadChats();
              });
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 54, 54, 54),
                            borderRadius: BorderRadius.circular(25)),
                        child: const Icon(Icons.question_answer_rounded,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 16),
                    const Text('Ver chats',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                )),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/product-form',
                  arguments: {'id': product.id}).then((_) {
                String token = storage.getItem('token');
                getProductsByToken(token).then((value) {
                  setState(() {
                    products = Future.value(value);
                  });
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(error.toString(),
                          style: const TextStyle(color: Colors.white))));
                });
              });
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 54, 54, 54),
                            borderRadius: BorderRadius.circular(25)),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 16),
                    const Text('Editar publicación',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                )),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Colors.grey.shade900,
                      title: const Text('Eliminar publicación',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                          '¿Estás seguro que deseas eliminar esta publicación?',
                          style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancelar',
                                style: TextStyle(color: Colors.white))),
                        TextButton(
                            onPressed: () {
                              if (product.id == null) {
                                return;
                              }
                              String token = storage.getItem('token');
                              deleteProduct(product.id ?? 0, token)
                                  .then((value) {
                                String token = storage.getItem('token');
                                getProductsByToken(token).then((value) {
                                  setState(() {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Publicación eliminada exitosamente'),
                                            backgroundColor: Color.fromARGB(
                                                255, 18, 87, 189)));
                                    products = Future.value(value);
                                    Navigator.pop(context);
                                    Navigator.pop(bottomSheetContext);
                                  });
                                }).catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(error.toString(),
                                              style: const TextStyle(
                                                  color: Colors.white))));
                                });
                              }).catchError((error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(error.toString(),
                                            style: const TextStyle(
                                                color: Colors.white))));
                              });
                            },
                            child: const Text('Eliminar',
                                style: TextStyle(color: Colors.red))),
                      ],
                    );
                  });
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 54, 54, 54),
                            borderRadius: BorderRadius.circular(25)),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 16),
                    const Text('Eliminar publicación',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  Widget chatsTab() {
    return FutureBuilder(
      future: chats,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
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
    );
  }

  Widget getChatView(Chat? chat) {
    if (chat == null) {
      return const Text('Error');
    }
    String lastMessage = '';
    String userSender = '';
    if (chat.lastMessage?.userIdSender == _user?.id) {
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
              'userId': _user?.id,
            },
          ).then((value) {
            initSocket();
            loadChats();
          });
        },
        child: Row(
          children: [
            FutureBuilder(
                future: getProduct(chat.productId ?? 0),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return getProductImage(snapshot.data);
                  } else if (snapshot.hasError) {
                    return const Text('Error');
                  } else {
                    return Shimmer.fromColors(
                        baseColor: Colors.grey.shade800,
                        highlightColor: Colors.grey.shade700,
                        child: Container(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: MediaQuery.of(context).size.width * 0.15,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(50))));
                  }
                }),
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

  Widget getProductImage(Product? product) {
    if (product == null) {
      return const Text('Error');
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child:
            product.productimages != null && product.productimages!.isNotEmpty
                ? Image.network(apiUrl + product.productimages![0].url,
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
                    child: const Icon(Icons.image, color: Colors.grey)));
  }
}
