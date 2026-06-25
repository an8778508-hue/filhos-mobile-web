import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/errors/failures.dart';
import 'package:escola/features/gallery/bloc/child_gallery_bloc.dart';
import 'package:escola/features/gallery/model/gallery_image_model.dart';
import 'package:escola/features/gallery/presentation/parent_gallery_screen.dart';
import 'package:escola/features/gallery/repo/gallery_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGalleryRepo extends Mock implements GalleryRepo {}

ChildGalleryBloc _bloc(GalleryRepo repo) => ChildGalleryBloc(repo, childId: 1);

List<GalleryImageModel> _images(int n) => [
      for (int i = 0; i < n; i++)
        GalleryImageModel(
          id: i + 1,
          image: 'https://example.com/photo_$i.jpg',
          caption: 'Caption $i',
          source: 'standalone',
        ),
    ];

void main() {
  testWidgets('grid renders one cell per returned image', (tester) async {
    final repo = MockGalleryRepo();
    when(() => repo.getChildGallery(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          asTeacher: any(named: 'asTeacher'),
        )).thenAnswer((_) async => Right<Failure, List<GalleryImageModel>>(_images(6)));

    final bloc = _bloc(repo);

    await tester.pumpWidget(MaterialApp(home: ParentGalleryScreen(bloc: bloc)));
    await bloc.fetch();
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    // One image cell per returned photo.
    expect(find.byType(CommonImage), findsNWidgets(6));
    expect(find.text('No photos yet'), findsNothing);
  });

  testWidgets('empty state is shown when there are no photos', (tester) async {
    final repo = MockGalleryRepo();
    when(() => repo.getChildGallery(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          asTeacher: any(named: 'asTeacher'),
        )).thenAnswer((_) async => const Right<Failure, List<GalleryImageModel>>([]));

    final bloc = _bloc(repo);

    await tester.pumpWidget(MaterialApp(home: ParentGalleryScreen(bloc: bloc)));
    await bloc.fetch();
    await tester.pumpAndSettle();

    expect(find.text('No photos yet'), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('loading state shows a progress indicator', (tester) async {
    final repo = MockGalleryRepo();
    final completer = Completer<Either<Failure, List<GalleryImageModel>>>();
    when(() => repo.getChildGallery(
          any(),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
          asTeacher: any(named: 'asTeacher'),
        )).thenAnswer((_) => completer.future);

    final bloc = _bloc(repo);

    await tester.pumpWidget(MaterialApp(home: ParentGalleryScreen(bloc: bloc)));
    // Kick off the load but DO NOT complete it.
    bloc.fetch();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete to avoid pending-timer issues at teardown.
    completer.complete(const Right<Failure, List<GalleryImageModel>>([]));
    await tester.pumpAndSettle();
  });
}
