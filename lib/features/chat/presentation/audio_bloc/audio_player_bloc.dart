import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/chat/presentation/audio_bloc/audio_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerBloc extends Bloc<AudioEvent, AudioState> {
  Duration? totalDuration;
  Duration? position;
  PlayerState? audioState;
  bool isPlaying = false;
  AudioPlayer? player;

  AudioPlayerBloc() : super(AudioInitial()) {
    on<AudioEvent>((event, emit) async {
      // if (event is InitAudioPlayers) {
      //   UpdateValuesLoading();
      //   await setUrl(event.url);
      //   initAudio();
      //   UpdateValuesSucceed();
      // } else if (event is AddAudioState) {
      //   emit(event.state);
      // }
    });
  }

  Future setUrl(String url) async {
    player = AudioPlayer();
    if (isHttpLink(url)) {
      totalDuration = await player?.setUrl(url);
    } else {
      totalDuration = await player?.setFilePath(url);
    }
  }

  initAudio() {
    player?.positionStream.listen((event) {
      position = event;
    });

    player?.playerStateStream.listen((state) async {
      isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        isPlaying = false;
      }
      add(AddAudioState(state: UpdateValuesSucceed()));
    });
  }

  playAudio() async {
    try {
      if (player?.playing == true) {
        await player?.seek(const Duration(seconds: 0));
      } else {
        player?.play();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  pauseAudio() {
    player?.pause();
  }

  stopAudio() {
    player?.stop();
  }

  resume() {
    player?.play();
  }

  seekAudio(Duration durationToSeek) async {
    await player?.seek(durationToSeek);
  }
}
