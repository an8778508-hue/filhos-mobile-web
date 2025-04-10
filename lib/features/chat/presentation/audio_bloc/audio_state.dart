part of 'audio_bloc.dart';

sealed class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object> get props => [];
}

final class AudioInitial extends AudioState {}

class UpdateValuesLoading extends AudioState {}

class UpdateValuesSucceed extends AudioState {}

class RecordingReseted extends AudioState {}

class PlayingStoped extends AudioState {}

class PlayingStarted extends AudioState {}
