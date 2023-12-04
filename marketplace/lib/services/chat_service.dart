import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:marketplace/models/chat_model.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/models/message_model.dart';

final String url = dotenv.get('API_URL');

Future<List<Chat>> getChatsByUser(String token) async {
  final response = await http.get(Uri.parse('$url/api/chats'), headers: {
    'Authorization': 'Bearer $token',
  });
  if (response.statusCode == 200) {
    final List<Chat> chats = chatListFromJson(response.body);
    return chats;
  } else {
    throw Exception(response.body);
  }
}

Future<List<Chat>> getChatsByProduct(int productId, String token) async {
  final response =
      await http.get(Uri.parse('$url/api/products/$productId/chats'), headers: {
    'Authorization': 'Bearer $token',
  });
  if (response.statusCode == 200) {
    final List<Chat> chats = chatListFromJson(response.body);
    return chats;
  } else {
    throw Exception(response.body);
  }
}

Future<List<Message>> getMessagesByChat(int id, String token) async {
  final response =
      await http.get(Uri.parse('$url/api/chats/$id/messages'), headers: {
    'Authorization': 'Bearer $token',
  });
  if (response.statusCode == 200) {
    final List<Message> messages = messageListFromJson(response.body);
    return messages;
  } else {
    throw Exception(response.body);
  }
}

Future<void> sendMessage(Message message, String token) async {
  var request = http.MultipartRequest("POST", Uri.parse('$url/api/messages'));
  int type = message.type ?? 0;
  switch (type) {
    case 1:
      request.fields['message'] = message.message ?? '';
      break;
    case 2:
      if (message.imageUrl == null) {
        throw Exception('Image is required');
      }
      request.files
          .add(await http.MultipartFile.fromPath('image', message.imageUrl!));
      break;
    case 3:
      request.fields['latitude'] = message.latitude ?? '';
      request.fields['longitude'] = message.longitude ?? '';
      break;
    default:
      throw Exception('Type is required');
  }
  request.fields['chat_id'] = message.chatId.toString();
  request.fields['type'] = type.toString();
  request.headers.addAll({'Authorization': 'Bearer $token'});
  final response = await request.send();

  if (response.statusCode != 200) {
    throw Exception(response.reasonPhrase);
  }
}

Future<Chat> createChat(int productId, String token) async {
  final response = await http.post(Uri.parse('$url/api/chats'), headers: {
    'Authorization': 'Bearer $token',
  }, body: {
    'product_id': productId.toString(),
  });

  if (response.statusCode == 200) {
    final Chat chat = chatFromJson(response.body);
    return chat;
  } else {
    throw Exception(response.body);
  }
}
