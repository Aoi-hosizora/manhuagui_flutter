import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';
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
import 'package:manhuagui_flutter/service/dio/retrofit/retrofit.dart';

// TODO rename retrofit.dart to rest_client.dart

abstract class RestClient {
  factory RestClient(Dio dio, {bool useCrawler = false}) {
    if (useCrawler) {
      return CrawlerClient(dio, baseUrl: WEB_HOMEPAGE_URL);
    }
    return RetrofitClient(dio, baseUrl: BASE_API_URL);
  }

  Future<Result<ResultPage<TinyManga>>> getAllMangas({required int page, required MangaOrder order});

  Future<Result<Manga>> getManga({required int mid});

  Future<Result<MangaChapter>> getMangaChapter({required int mid, required int cid});

  Future<Result<RandomMangaInfo>> getRandomManga();

  Future<Result<MangaGroupList>> getHotSerialMangas();

  Future<Result<MangaGroupList>> getFinishedMangas();

  Future<Result<MangaGroupList>> getLatestMangas();

  Future<Result<HomepageMangaGroupList>> getHomepageMangas();

  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({required int page, int limit = 42});

  Future<Result<ResultPage<Category>>> getGenres();

  Future<Result<ResultPage<TinyManga>>> getGenreMangas({required String genre, required String zone, required String age, required String status, required int page, required MangaOrder order});

  Future<Result<ResultPage<SmallManga>>> searchMangas({required String keyword, required int page, required MangaOrder order});

  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({required String genre, required String zone, required String age, required int page, required AuthorOrder order});

  Future<Result<Author>> getAuthor({required int aid});

  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({required int aid, required int page, required MangaOrder order});

  Future<Result<ResultPage<MangaRanking>>> getDayRanking({required String type});

  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({required String type});

  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({required String type});

  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({required String type});

  Future<Result<ResultPage<Comment>>> getMangaComments({required int mid, required int page});

  Future<Result<LoginCheckResult>> checkUserLogin({required String token});

  Future<Result<User>> getUserInfo({required String token});

  Future<Result<Token>> login({required String username, required String password});

  Future<Result> recordManga({required String token, required int mid, required int cid});

  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({required String token, required int page});

  Future<Result<ShelfStatus>> checkShelfManga({required String token, required int mid});

  Future<Result> addToShelf({required String token, required int mid});

  Future<Result> removeFromShelf({required String token, required int mid});

  Future<Result<ResultPage<Message>>> getMessages();

  Future<Result<LatestMessage>> getLatestMessage();
}
