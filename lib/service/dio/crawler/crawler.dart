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
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/crawler/_impl.dart';

abstract class CrawlerClient implements RestClient {
  factory CrawlerClient(Dio _dio, {required String baseUrl}) = CrawlerImpl;

  @override
  Future<Result<ResultPage<TinyManga>>> getAllMangas({required int page, required MangaOrder order});

  @override
  Future<Result<Manga>> getManga({required int mid});

  @override
  Future<Result<MangaChapter>> getMangaChapter({required int mid, required int cid});

  @override
  Future<Result<RandomMangaInfo>> getRandomManga();

  @override
  Future<Result<MangaGroupList>> getHotSerialMangas();

  @override
  Future<Result<MangaGroupList>> getFinishedMangas();

  @override
  Future<Result<MangaGroupList>> getLatestMangas();

  @override
  Future<Result<HomepageMangaGroupList>> getHomepageMangas();

  @override
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({required int page, int limit = 42});

  @override
  Future<Result<ResultPage<Category>>> getGenres();

  @override
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({required String genre, required String zone, required String age, required String status, required int page, required MangaOrder order});

  @override
  Future<Result<ResultPage<SmallManga>>> searchMangas({required String keyword, required int page, required MangaOrder order});

  @override
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({required String genre, required String zone, required String age, required int page, required AuthorOrder order});

  @override
  Future<Result<Author>> getAuthor({required int aid});

  @override
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({required int aid, required int page, required MangaOrder order});

  @override
  Future<Result<ResultPage<MangaRanking>>> getDayRanking({required String type});

  @override
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({required String type});

  @override
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({required String type});

  @override
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({required String type});

  @override
  Future<Result<ResultPage<Comment>>> getMangaComments({required int mid, required int page});

  @override
  Future<Result<LoginCheckResult>> checkUserLogin({required String token});

  @override
  Future<Result<User>> getUserInfo({required String token});

  @override
  Future<Result<Token>> login({required String username, required String password});

  @override
  Future<Result> recordManga({required String token, required int mid, required int cid});

  @override
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({required String token, required int page});

  @override
  Future<Result<ShelfStatus>> checkShelfManga({required String token, required int mid});

  @override
  Future<Result> addToShelf({required String token, required int mid});

  @override
  Future<Result> removeFromShelf({required String token, required int mid});

  @override
  Future<Result<ResultPage<Message>>> getMessages();

  @override
  Future<Result<LatestMessage>> getLatestMessage();
}
