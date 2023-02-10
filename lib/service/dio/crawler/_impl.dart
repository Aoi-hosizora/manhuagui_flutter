import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:manhuagui_flutter/service/dio/crawler/crawler.dart';
import 'package:manhuagui_flutter/service/dio/crawler/_http.dart' as http;
import 'package:web_scraper/web_scraper.dart';

class CrawlerImpl implements CrawlerClient {
  CrawlerImpl(this._dio, {required this.baseUrl});

  final Dio _dio;
  final String baseUrl;

  @override
  Future<Result<ResultPage<TinyManga>>> getAllMangas({required int page, required MangaOrder order}) async {
    final scraper = WebScraper();

    var html = await http.request(_dio, baseUrl, 'GET', '/');
    print(html);
    var ok = scraper.loadFromString(html.data ?? '');
    print(ok);

    throw UnimplementedError();
  }

  @override
  Future<Result<Manga>> getManga({required int mid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<MangaChapter>> getMangaChapter({required int mid, required int cid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<RandomMangaInfo>> getRandomManga() {
    throw UnimplementedError();
  }

  @override
  Future<Result<MangaGroupList>> getHotSerialMangas() {
    throw UnimplementedError();
  }

  @override
  Future<Result<MangaGroupList>> getFinishedMangas() {
    throw UnimplementedError();
  }

  @override
  Future<Result<MangaGroupList>> getLatestMangas() {
    throw UnimplementedError();
  }

  @override
  Future<Result<HomepageMangaGroupList>> getHomepageMangas() {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({required int page, int limit = 42}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<Category>>> getGenres() {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({required String genre, required String zone, required String age, required String status, required int page, required MangaOrder order}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<SmallManga>>> searchMangas({required String keyword, required int page, required MangaOrder order}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({required String genre, required String zone, required String age, required int page, required AuthorOrder order}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Author>> getAuthor({required int aid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({required int aid, required int page, required MangaOrder order}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getDayRanking({required String type}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({required String type}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({required String type}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({required String type}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<Comment>>> getMangaComments({required int mid, required int page}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<LoginCheckResult>> checkUserLogin({required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<User>> getUserInfo({required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Token>> login({required String username, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<Result> recordManga({required String token, required int mid, required int cid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({required String token, required int page}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ShelfStatus>> checkShelfManga({required String token, required int mid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result> addToShelf({required String token, required int mid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result> removeFromShelf({required String token, required int mid}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<ResultPage<Message>>> getMessages() {
    throw UnimplementedError();
  }

  @override
  Future<Result<LatestMessage>> getLatestMessage() {
    throw UnimplementedError();
  }
}
