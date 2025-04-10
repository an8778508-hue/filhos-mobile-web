import 'dart:io';

import 'package:escola/core/errors/failures.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ImagesMessageBloc extends Bloc<ChatEvent, ChatState> {
  final ChatUser? contactUser;
  final ChatBloc chatBloc;
  final ChildModel? child;

  String? content;
  List<XFile> imagesInTheField = [];
  List<Message> temporaryMessages = [];

  ImagesMessageBloc({
    required this.chatBloc,
    required this.child,
    required this.contactUser,
  }) : super(ChatInitial()) {
    on<ChatEvent>((event, emit) async {
      if (event is AddImages) {
        emit(UpdateValuesLoading());
        imagesInTheField.addAll(event.images);
        emit(UpdateValuesSucceed());
      } else if (event is DeleteImage) {
        emit(UpdateValuesLoading());
        imagesInTheField.removeAt(event.index);
        emit(UpdateValuesSucceed());
      } else if (event is SendImagesMessage) {
        if (contactUser != null) {
          emit(SendMessageLoading());
          final files = await _updateUIWithTemporaryImages();

          return await _uploadToFirestore(files);
        }
      }
    });
  }

  _uploadToFirestore(List<XFile> filesToUpload) async {
    try {
      if (chatBloc.currentUser == null) return;
      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef = storageRef.child("chat/${chatBloc.currentUser!.id}/${contactUser?.id ?? "reciever"}/images");

      final imagesLinks = await _uploadImages(filesToUpload, imagesRef);

      for (int i = 0; i < imagesLinks.length; i++) {
        final imageLink = imagesLinks[i];
        final temporaryImage = temporaryMessages[i];

        final message = temporaryImage.copyWith(content: imageLink);

        chatBloc.add(SendMessage(message: message));
      }
      temporaryMessages = [];
    } on Failure catch (e) {
      debugPrint("Error $e");
      chatBloc.add(AddState(state: SendMessageError(failure: e)));
      _removeTemporaryMessages();
    }
  }

  _removeTemporaryMessages() {
    for (var i = 0; i < temporaryMessages.length; i++) {
      final tempMessage = temporaryMessages[i];
      chatBloc.add(RemoveTemporaryMessages(message: tempMessage));
    }
    temporaryMessages = [];
  }

  Future<List<Message>> getMessagesFromImages(List<XFile> images) async {
    if (chatBloc.currentUser == null || contactUser == null) return [];
    List<Message> messages = [];
    for (var imageFileLink in images) {
      final bool isImage = endsWithImageExtenstion(imageFileLink.path);

      final message = await ChatHelper.buildMessageFromContent(
          content: imageFileLink.path,
          sender: chatBloc.currentUser!,
          reciever: contactUser!,
          child: child,
          type: isImage ? MessageType.image : MessageType.file);

      messages.add(message);
    }
    return messages;
  }

  // update UI with temporary messages
  Future<List<XFile>> _updateUIWithTemporaryImages() async {
    final files = imagesInTheField;
    imagesInTheField = [];
    List<Message> messages = await getMessagesFromImages(files);
    temporaryMessages = messages;
    chatBloc.add(SendTemporaryMessages(messages: messages));
    return files;
  }

  Future<List<String>> _uploadImages(List<XFile> images, Reference imagesRef) async {
    try {
      List<String> imageUrls = [];
      for (var i = 0; i < images.length; i++) {
        imageUrls.add(await _uploadImage(images[i], imagesRef));
      }
      return imageUrls;
    } catch (e) {
      debugPrint("Error $e");
      throw const ServerFailure(message: "Failed to upload images");
    }
  }

  Future<String> _uploadImage(XFile image, Reference imagesRef) async {
    final singleImageRef = imagesRef.child(image.name);
    final File file = File(image.path);

    UploadTask uploadTask = singleImageRef.putFile(file);
    String downloadUrl = "";
    await uploadTask.whenComplete(() async {
      downloadUrl = await singleImageRef.getDownloadURL();
    });

    return downloadUrl;
  }
}
