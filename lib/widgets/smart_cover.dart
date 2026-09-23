import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song_model.dart';

class SmartCover extends StatefulWidget {
  final SongModel song;
  final double size;
  final double borderRadius;

  const SmartCover({
    super.key,
    required this.song,
    required this.size,
    this.borderRadius = 8.0,
  });

  @override
  State<SmartCover> createState() => _SmartCoverState();
}

class _SmartCoverState extends State<SmartCover> {
  bool _triedHqDefault = false;

  @override
  void didUpdateWidget(covariant SmartCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.coverUrl != widget.song.coverUrl) {
      _triedHqDefault = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Local bytes — highest priority
    if (widget.song.coverBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.memory(
          widget.song.coverBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }

    if (widget.song.coverUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _buildFallback(),
      );
    }

    String currentUrl = widget.song.coverUrl;
    if (_triedHqDefault && currentUrl.contains('maxresdefault')) {
      currentUrl = currentUrl.replaceAll('maxresdefault', 'hqdefault');
    }

    // 4:3 thumbnails (hqdefault) need extra scale to fill square without bars
    final bool is4x3 = currentUrl.contains('hqdefault') || currentUrl.contains('sddefault');
    final double scale = is4x3 ? 1.3333 : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Transform.scale(
        scale: scale,
        child: CachedNetworkImage(
          imageUrl: currentUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            if (!_triedHqDefault && widget.song.coverUrl.contains('maxresdefault')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _triedHqDefault = true;
                  });
                }
              });
              return const SizedBox();
            }
            return Transform.scale(
              scale: 1.0 / scale,
              child: _buildFallback(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: const Color(0xFF2A2A2A),
      child: Icon(
        Icons.music_note,
        color: Colors.grey[600],
        size: widget.size * 0.45,
      ),
    );
  }
}
