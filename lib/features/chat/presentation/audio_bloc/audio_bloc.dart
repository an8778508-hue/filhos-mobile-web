import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/models/chat_user.dart';
import 'package:escola/features/chat/models/message.dart';
import 'package:escola/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:escola/features/chat/presentation/bloc/chat_helper.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

part 'audio_event.dart';
part 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final ChatUser? contactUser;
  final ChatBloc chatBloc;
  final ChildModel? child;

  Duration currentRecordTime = Duration.zero;

  RecordingState recordingState = RecordingState.noRecording;
  Timer? recordTimer;

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? outputFile;

  final Map<String, AudioPlayer> messagesAudioPlayers = {};
  final Map<String, Duration> audioPlayersPosition = {};
  final Map<String, PlayState> audioPlayersIsPlaying = {};
  final Map<String, StreamSubscription<Duration>> positionStreams = {};
  final Map<String, StreamSubscription<PlayerState>> statesStream = {};

  String? currentPLayingMessageId;

  AudioBloc({
    required this.chatBloc,
    required this.child,
    required this.contactUser,
  }) : super(AudioInitial()) {
    on<AudioEvent>((event, emit) async {
      if (event is StartRecording) {
        if (contactUser != null) {
          emit(UpdateValuesLoading());
          await startRecordingAction(emit);
          emit(UpdateValuesSucceed());
        }
      } else if (event is DeleteRecording) {
        emit(UpdateValuesLoading());
        await stopRecordAction(emit);
        emit(UpdateValuesSucceed());
      } else if (event is SendRecordingMessage) {
        await sendRecordMessage(emit);
      } else if (event is AddTick) {
        emit(UpdateValuesLoading());
        currentRecordTime += const Duration(seconds: 1);
        emit(UpdateValuesSucceed());
      } else if (event is InitAudioPlayers) {
        await _initAudios(event, emit);
      } else if (event is PlayAudio) {
        await _playAudio(event, emit);
      } else if (event is PauseAudio) {
        await _pauseAudio(event, emit);
      } else if (event is ResumeAudio) {
        await _resumeAudio(event, emit);
      } else if (event is StopAudio) {
        await _stopAudio(event, emit);
      } else if (event is SeekAudio) {
        await _seekAudio(event, emit);
      } else if (event is AddAudioState) {
        emit(UpdateValuesLoading());
        emit(event.state);
      }
    });
  }

  Future<void> _playAudio(PlayAudio event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioPlayer = messagesAudioPlayers[event.message.id];
    if (currentPLayingMessageId != null) {
      final currentAudioPlayer = messagesAudioPlayers[currentPLayingMessageId];
      if (currentAudioPlayer != null) await currentAudioPlayer.stop();
    }
    if (audioPlayer != null) {
      try {
        if (audioPlayer.playing) {
          await audioPlayer.seek(const Duration(seconds: 0));
        } else {
          audioPlayer.play();
        }
      } catch (e) {
        debugPrint(e.toString());
      }
      emit(UpdateValuesSucceed());
    }
  }

  Future<void> _pauseAudio(PauseAudio event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioPlayer = messagesAudioPlayers[event.message.id];
    if (audioPlayer != null) {
      await audioPlayer.pause();
      emit(UpdateValuesSucceed());
    }
  }

  Future<void> _resumeAudio(ResumeAudio event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioPlayer = messagesAudioPlayers[event.message.id];
    if (audioPlayer != null) {
      await audioPlayer.play();

      emit(UpdateValuesSucceed());
    }
  }

  Future<void> _stopAudio(StopAudio event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioPlayer = messagesAudioPlayers[event.message.id];
    if (audioPlayer != null) {
      await audioPlayer.stop();
      emit(UpdateValuesSucceed());
    }
  }

  Future<void> _seekAudio(SeekAudio event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioPlayer = messagesAudioPlayers[event.message.id];
    if (audioPlayer != null) {
      await audioPlayer.seek(event.position);
      emit(UpdateValuesSucceed());
    }
  }

  Future<void> _initAudios(InitAudioPlayers event, Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());
    final audioMessages = event.messages.where((element) => element.type == MessageType.audio).toList();

    await Future.wait(audioMessages.map((e) async => await _setUrlToMessage(e)));

    emit(UpdateValuesLoading());
    for (var i = 0; i < event.messages.length; i++) {
      final message = event.messages[i];
      if (message.type == MessageType.audio) {
        _setListenerToMessage(message);
      }
    }
    emit(UpdateValuesSucceed());
  }

  Future<void> _setUrlToMessage(Message message) async {
    if (messagesAudioPlayers[message.id] == null) {
      add(AddAudioState(state: UpdateValuesSucceed()));

      final audioPlayer = AudioPlayer();
      if (isHttpLink(message.content)) {
        await audioPlayer.setUrl(message.content);
      } else {
        await audioPlayer.setFilePath(message.content);
      }
      messagesAudioPlayers[message.id] = audioPlayer;
      // _setListenerToMessage(message);
      add(AddAudioState(state: UpdateValuesSucceed()));
    }
  }

  Future<void> _setListenerToMessage(Message message) async {
    final player = messagesAudioPlayers[message.id];

    final bool newMessage = positionStreams[message.id] == null && statesStream[message.id] == null;

    if (newMessage) {
      if (player != null) {
        try {
          final positionStream = player.positionStream.listen((event) {
            audioPlayersPosition[message.id] = event;
            add(AddAudioState(state: UpdateValuesSucceed()));
          });

          positionStreams[message.id] = positionStream;

          final stateStream = player.playerStateStream.listen((state) async {
            audioPlayersIsPlaying[message.id] = state.playing ? PlayState.playing : PlayState.notPlaying;
            currentPLayingMessageId = state.playing ? message.id : null;

            if (state.processingState == ProcessingState.completed) {
              currentPLayingMessageId = null;
              audioPlayersIsPlaying[message.id] = PlayState.notPlaying;
            } else if (state.processingState == ProcessingState.loading) {
              audioPlayersIsPlaying[message.id] = PlayState.loading;
            }
            add(AddAudioState(state: UpdateValuesSucceed()));
          });
          statesStream[message.id] = stateStream;
        } catch (e) {
          debugPrint("Error : $e");
        }
      }
    }
  }

  Future sendRecordMessage(Emitter<AudioState> emit) async {
    if (outputFile != null && chatBloc.currentUser != null && contactUser != null) {
      emit(UpdateValuesLoading());
      await stopRecordAction(emit);
      final tempMessage = await ChatHelper.buildMessageFromContent(content: outputFile!, sender: chatBloc.currentUser!, reciever: contactUser!, child: child, type: MessageType.audio);

      // _setUrlToMessage(tempMessage, emit);
      // _setListenerToMessage(tempMessage);
      chatBloc.add(SendTemporaryMessages(messages: [tempMessage]));

      await uploadRecord(tempMessage, emit);
    }
  }

  Future<void> uploadRecord(Message tempMessage, Emitter<AudioState> emit) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      if (chatBloc.currentUser != null && outputFile != null) {
        final dateInMilliseconds = DateTime.now().millisecondsSinceEpoch;

        final audioRef = storageRef.child("chat/${chatBloc.currentUser?.id}/${contactUser?.id ?? "reciever"}/audios").child("$dateInMilliseconds.aac");

        final File file = File(outputFile!);

        UploadTask uploadTask = audioRef.putFile(file);

        String audioDownloadUrl = "";

        await uploadTask.whenComplete(() async {
          audioDownloadUrl = await audioRef.getDownloadURL();
        });
        if (stringNotNullOrEmpty(audioDownloadUrl)) {
          uploadToFirestore(audioDownloadUrl, emit);
        }
      }
    } catch (e) {
      chatBloc.add(RemoveTemporaryMessages(message: tempMessage));
      debugPrint("Error : $e");
    }
  }

  void uploadToFirestore(String recordUrl, Emitter<AudioState> emit) async {
    if (chatBloc.currentUser == null || contactUser == null) return;
    final uploadedMessage = await ChatHelper.buildMessageFromContent(content: recordUrl, sender: chatBloc.currentUser!, reciever: contactUser!, child: child, type: MessageType.audio);
    await _setUrlToMessage(uploadedMessage);
    await _setListenerToMessage(uploadedMessage);
    chatBloc.add(SendMessage(message: uploadedMessage));
  }

  Future<void> startRecordingAction(Emitter<AudioState> emit) async {
    emit(UpdateValuesLoading());

    try {
      final tempDir = await getTemporaryDirectory();
      outputFile = '${tempDir.path}/recording${DateTime.now().millisecondsSinceEpoch}.aac';
      recordingState = RecordingState.recording;
      if (await _audioRecorder.hasPermission()) {
        if (outputFile != null) {
          await _audioRecorder.start(
            RecordConfig(
              encoder: AudioEncoder.aacLc,
            ),
            path: outputFile!,
          );
        }
        recordTimer?.cancel();
        recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) => add(AddTick()));
      }
      emit(UpdateValuesSucceed());
    } catch (e) {
      debugPrint("Error : $e");
    }
  }

  Future<void> stopRecordAction(Emitter<AudioState> emit) async {
    try {
      emit(UpdateValuesLoading());

      await _audioRecorder.stop();
      recordingState = RecordingState.noRecording;
      recordTimer?.cancel();
      currentRecordTime = Duration.zero;
      emit(UpdateValuesSucceed());
    } catch (e) {
      debugPrint("Error : $e");
    }
  }

  @override
  Future<void> close() {
    recordTimer?.cancel();
    _audioRecorder.stop();
    _audioRecorder.dispose();
    messagesAudioPlayers.forEach((key, value) async {
      await value.dispose();
    });
    positionStreams.forEach((key, value) async {
      await value.cancel();
    });
    statesStream.forEach((key, value) async {
      await value.cancel();
    });

    return super.close();
  }
}

enum RecordingState { noRecording, recording, stoped }

enum PlayState { notPlaying, playing, ready, loading }
