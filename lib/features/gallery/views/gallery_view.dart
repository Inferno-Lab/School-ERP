import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class GalleryController extends GetxController with Loadable {
  final album = 0.obs;
  List<GalleryAlbum> albums = [];

  @override
  Future<void> load() => run(() async {
    albums = await Get.find<GalleryRepository>().all();
  }, isEmpty: () => albums.isEmpty);
}

class GalleryView extends GetView<GalleryController> {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final albums = controller.albums;
      final index = albums.isEmpty ? 0 : controller.album.value.clamp(0, albums.length - 1);
      final current = albums.isEmpty ? null : albums[index];
      return FeaturePage(
        title: 'gallery.title',
        subtitle: 'gallery.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: current == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: albums.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => ChoiceChip(
                            label: Text(albums[i].title),
                            selected: index == i,
                            onSelected: (_) => controller.album.value = i,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(current.blurb, style: context.text.bodyMedium),
                      Text(Formatters.fullDate(current.date), style: context.text.bodySmall),
                      const SizedBox(height: 12),
                      MasonryGridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: context.isWide ? 3 : 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        itemCount: current.photos.length,
                        itemBuilder: (context, photoIndex) {
                          final photo = current.photos[photoIndex];
                          return GestureDetector(
                            onTap: () => Get.to<void>(
                              () => GalleryViewer(photos: current.photos, initial: photoIndex),
                              transition: Transition.fadeIn,
                            ),
                            child: Hero(
                              tag: photo.id,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: photo.url,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => Container(
                                    height: 140,
                                    color: context.colors.surfaceContainer,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}

class GalleryViewer extends StatefulWidget {
  const GalleryViewer({required this.photos, required this.initial, super.key});

  final List<GalleryPhoto> photos;
  final int initial;

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late final PageController _page = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  child: Hero(
                    tag: photo.id,
                    child: CachedNetworkImage(imageUrl: photo.url, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(photo.caption, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
