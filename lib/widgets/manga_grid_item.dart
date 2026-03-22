import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../utils/date_utils.dart';

class MangaGridItem extends StatelessWidget {
  final MangaModel manga;
  final VoidCallback onTap;

  const MangaGridItem({
    super.key,
    required this.manga,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool showUp = isToday(manga.createdAt);

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE (chiếm phần lớn chiều cao)
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    manga.coverUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// UP BADGE
                if (showUp)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'UP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          /// TITLE
          Text(
            manga.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
