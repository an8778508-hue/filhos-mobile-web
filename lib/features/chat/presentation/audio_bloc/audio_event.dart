part of 'audio_bloc.dart';

sealed class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object> get props => [];
}

class StartRecording extends AudioEvent {}

class StopRecording extends AudioEvent {}

class DeleteRecording extends AudioEvent {}

class AddTick extends AudioEvent {}

class RemoveTick extends AudioEvent {}

class OpenRecorderAndPlayer extends AudioEvent {}

class SendRecordingMessage extends AudioEvent {}

class InitAudioPlayers extends AudioEvent {
  final List<Message> messages;

  const InitAudioPlayers({required this.messages});
}

class AddAudioState extends AudioEvent {
  final AudioState state;

  const AddAudioState({required this.state});
}

class ResumeAudio extends AudioEvent {
  final Message message;

  const ResumeAudio({required this.message});
}

class PlayAudio extends AudioEvent {
  final Message message;

  const PlayAudio({required this.message});
}

class PauseAudio extends AudioEvent {
  final Message message;

  const PauseAudio({required this.message});
}

class StopAudio extends AudioEvent {
  final Message message;

  const StopAudio({required this.message});
}

class SeekAudio extends AudioEvent {
  final Message message;
  final Duration position;

  const SeekAudio({required this.message, required this.position});
}
