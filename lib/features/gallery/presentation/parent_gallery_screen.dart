import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/components/image/photo_viewer.dart';
import 'package:escola/features/gallery/bloc/child_gallery_bloc.dart';
import 'package:escola/features/gallery/bloc/child_gallery_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A child's dedicated photo album: a scrollable grid of photos with
/// pull-to-refresh, infinite scroll, and tap-to-fullscreen.
///
/// The [bloc] is injected so it can be mocked in widget tests.
class ParentGalleryScreen extends StatefulWidget {
  final ChildGalleryBloc bloc;
  final String title;

  const ParentGalleryScreen({
    super.key,
    required this.bloc,
    this.title = 'Gallery',
  });

  @override
  State<ParentGalleryScreen> createState() => _ParentGalleryScreenState();
}

class _ParentGalleryScreenState extends State<ParentGalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      widget.bloc.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: BlocBuilder<ChildGalleryBloc, ChildGalleryState>(
          builder: (context, state) {
            final gs = state.galleryState;

            if (gs.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.data.isEmpty) {
              return const Center(child: Text('No photos yet'));
            }

            return RefreshIndicator(
              onRefresh: () => widget.bloc.fetch(reload: true),
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(4),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: state.data.length + (gs.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.data.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final item = state.data[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotoViewer(url: item.image, tag: 'gallery_${item.id}'),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CommonImage(
                        imageUrl: item.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
