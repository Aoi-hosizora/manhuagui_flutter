import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/entity.dart';

class NewBadge extends StatelessWidget {
  const NewBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        ),
        child: Text(
          'NEW',
          style: TextStyle(
            fontSize: 9,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

enum DownloadBadgeState {
  downloading,
  done,
  failed,
}

class DownloadBadge extends StatelessWidget {
  const DownloadBadge({
    Key? key,
    required this.state,
  }) : super(key: key);

  final DownloadBadgeState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 1,
      right: 1,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.25, horizontal: 1.25),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state == DownloadBadgeState.downloading
              ? Colors.blue
              : state == DownloadBadgeState.done
                  ? Colors.green
                  : Colors.red,
        ),
        child: Icon(
          state == DownloadBadgeState.downloading
              ? Icons.download
              : state == DownloadBadgeState.done
                  ? Icons.file_download_done
                  : Icons.priority_high,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  static DownloadBadge? fromEntity({required DownloadedChapter? entity}) {
    if (entity == null) {
      return null;
    }
    return DownloadBadge(
      state: !entity.allTried || entity.needUpdate
          ? DownloadBadgeState.downloading
          : entity.succeeded
              ? DownloadBadgeState.done
              : DownloadBadgeState.failed,
    );
  }
}
