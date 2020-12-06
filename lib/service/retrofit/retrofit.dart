import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:retrofit/http.dart';

part 'retrofit.g.dart';

@RestApi()
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET('/manga')
  Future<Result<ResultPage<TinyManga>>> getAllMangas({@Query('page') int page, @Query('order') MangaOrder order});

  @GET('/manga/{mid}')
  Future<Result<Manga>> getManga({@Path() int mid});

  @GET('/manga/{mid}/{cid}')
  Future<Result<MangaChapter>> getMangaChapter({@Path() int mid, @Path() int cid});

  @GET('/list/serial')
  Future<Result<MangaGroupList>> getHotSerialMangas();

  @GET('/list/finish')
  Future<Result<MangaGroupList>> getFinishedMangas();

  @GET('/list/latest')
  Future<Result<MangaGroupList>> getLatestMangas();

  @GET('/list/updated')
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({@Query('page') int page, @Query('limit') int limit = 42});

  @GET('/category/genre')
  Future<Result<ResultPage<Category>>> getGenres();

  @GET('/category/genre/{genre}')
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({@Path() String genre, @Query('zone') String zone, @Query('age') String age, @Query('status') String status, @Query('page') int page, @Query('order') MangaOrder order});

  @GET('/search/{keyword}')
  Future<Result<ResultPage<SmallManga>>> searchMangas({@Path() String keyword, @Query('page') int page, @Query('order') MangaOrder order});

  @GET('/author')
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({@Query('genre') String genre, @Query('zone') String zone, @Query('age') String age, @Query('page') int page, @Query('order') AuthorOrder order});

  @GET('/author/{aid}')
  Future<Result<Author>> getAuthor({@Path() int aid});

  @GET('/author/{aid}/manga')
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({@Path() int aid, @Query('page') int page, @Query('order') MangaOrder order});

  @GET('/rank/day')
  Future<Result<ResultPage<MangaRank>>> getDayRanking({@Query('type') String type});

  @GET('/rank/week')
  Future<Result<ResultPage<MangaRank>>> getWeekRanking({@Query('type') String type});

  @GET('/rank/month')
  Future<Result<ResultPage<MangaRank>>> getMonthRanking({@Query('type') String type});

  @GET('/rank/total')
  Future<Result<ResultPage<MangaRank>>> getTotalRanking({@Query('type') String type});

  @GET('/comment/manga/{uid}')
  Future<Result<ResultPage<Comment>>> getMangaComments({@Path() int mid, @Query('page') int page});
}
