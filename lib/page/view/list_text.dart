import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/page/author.dart';
import 'package:manhuagui_flutter/page/genre.dart';

/// View for [Category] list.
/// Used in [MangaPage].
class GenreListText extends StatefulWidget {
  const GenreListText({
    Key key,
    @required this.genres,
  })  : assert(genres != null),
        super(key: key);

  final List<Category> genres;

  @override
  _GenreListTextState createState() => _GenreListTextState();
}

class _GenreListTextState extends State<GenreListText> {
  var _tapDowns = <bool>[];

  @override
  void initState() {
    _tapDowns = widget.genres.map((_) => false).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '',
        style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 13),
        children: [
          for (var i = 0; i < widget.genres.length; i++) ...[
            TextSpan(
              text: widget.genres[i].title,
              style: TextStyle(
                color: Colors.transparent,
                shadows: [
                  Shadow(
                    color: _tapDowns[i] ? Theme.of(context).primaryColor : Colors.black,
                    offset: Offset(0, -1),
                  ),
                ],
                decoration: TextDecoration.underline,
                decorationColor: _tapDowns[i] ? Theme.of(context).primaryColor : Colors.black,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = (() => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (c) => GenrePage(
                          genre: widget.genres[i].toTiny(),
                        ),
                      ),
                    ))
                ..onTapDown = ((_) => mountedSetState(() => _tapDowns[i] = true))
                ..onTapUp = ((_) => mountedSetState(() => _tapDowns[i] = false))
                ..onTapCancel = (() => mountedSetState(() => _tapDowns[i] = false)),
            ),
            if (i != widget.genres.length - 1) TextSpan(text: ' / '),
          ],
          TextSpan(text: ''),
        ],
      ),
    );
  }
}

/// View for [TinyAuthor] list.
/// Used in [MangaPage].
class AuthorListText extends StatefulWidget {
  const AuthorListText({
    Key key,
    @required this.authors,
  })  : assert(authors != null),
        super(key: key);

  final List<TinyAuthor> authors;

  @override
  _AuthorListTextState createState() => _AuthorListTextState();
}

class _AuthorListTextState extends State<AuthorListText> {
  var _tapDowns = <bool>[];

  @override
  void initState() {
    _tapDowns = widget.authors.map((_) => false).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: '',
        style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 13),
        children: [
          for (var i = 0; i < widget.authors.length; i++) ...[
            TextSpan(
              text: widget.authors[i].name,
              style: TextStyle(
                color: Colors.transparent,
                shadows: [
                  Shadow(
                    color: _tapDowns[i] ? Theme.of(context).primaryColor : Colors.black,
                    offset: Offset(0, -1),
                  ),
                ],
                decoration: TextDecoration.underline,
                decorationColor: _tapDowns[i] ? Theme.of(context).primaryColor : Colors.black,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = (() => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (c) => AuthorPage(
                          id: widget.authors[i].aid,
                          name: widget.authors[i].name,
                          url: widget.authors[i].url,
                        ),
                      ),
                    ))
                ..onTapDown = ((_) => mountedSetState(() => _tapDowns[i] = true))
                ..onTapUp = ((_) => mountedSetState(() => _tapDowns[i] = false))
                ..onTapCancel = (() => mountedSetState(() => _tapDowns[i] = false)),
            ),
            if (i != widget.authors.length - 1) TextSpan(text: ' / '),
          ],
          TextSpan(text: ''),
        ],
      ),
    );
  }
}
