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
import 'package:retrofit/http.dart';

part 'retrofit.g.dart';

@RestApi()
abstract class RetrofitClient implements RestClient {
  factory RetrofitClient(Dio dio, {required String baseUrl}) = _RetrofitClient;

  @override
  @GET('/manga')
  Future<Result<ResultPage<TinyManga>>> getAllMangas({@Query('page') required int page, @Query('order') required MangaOrder order});

  @override
  @GET('/manga/{mid}')
  Future<Result<Manga>> getManga({@Path() required int mid});

  @override
  @GET('/manga/{mid}/{cid}')
  Future<Result<MangaChapter>> getMangaChapter({@Path() required int mid, @Path() required int cid});

  @override
  @GET('/manga/random')
  Future<Result<RandomMangaInfo>> getRandomManga();

  @override
  @GET('/list/serial')
  Future<Result<MangaGroupList>> getHotSerialMangas();

  @override
  @GET('/list/finish')
  Future<Result<MangaGroupList>> getFinishedMangas();

  @override
  @GET('/list/latest')
  Future<Result<MangaGroupList>> getLatestMangas();

  @override
  @GET('/list/homepage')
  Future<Result<HomepageMangaGroupList>> getHomepageMangas();

  @override
  @GET('/list/updated')
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({@Query('page') required int page, @Query('limit') int limit = 42});

  @override
  @GET('/category/genre')
  Future<Result<ResultPage<Category>>> getGenres();

  @override
  @GET('/category/genre/{genre}')
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({@Path() required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('status') required String status, @Query('page') required int page, @Query('order') required MangaOrder order});

  @override
  @GET('/search/{keyword}')
  Future<Result<ResultPage<SmallManga>>> searchMangas({@Path() required String keyword, @Query('page') required int page, @Query('order') required MangaOrder order});

  @override
  @GET('/author')
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({@Query('genre') required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('page') required int page, @Query('order') required AuthorOrder order});

  @override
  @GET('/author/{aid}')
  Future<Result<Author>> getAuthor({@Path() required int aid});

  @override
  @GET('/author/{aid}/manga')
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({@Path() required int aid, @Query('page') required int page, @Query('order') required MangaOrder order});

  @override
  @GET('/rank/day')
  Future<Result<ResultPage<MangaRanking>>> getDayRanking({@Query('type') required String type});

  @override
  @GET('/rank/week')
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({@Query('type') required String type});

  @override
  @GET('/rank/month')
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({@Query('type') required String type});

  @override
  @GET('/rank/total')
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({@Query('type') required String type});

  @override
  @GET('/comment/manga/{mid}')
  Future<Result<ResultPage<Comment>>> getMangaComments({@Path() required int mid, @Query('page') required int page});

  @override
  @POST('/user/check_login')
  Future<Result<LoginCheckResult>> checkUserLogin({@Header('Authorization') required String token});

  @override
  @GET('/user/info')
  Future<Result<User>> getUserInfo({@Header('Authorization') required String token});

  @override
  @POST('/user/login')
  Future<Result<Token>> login({@Query('username') required String username, @Query('password') required String password});

  @override
  @POST('/user/manga/{mid}/{cid}')
  Future<Result> recordManga({@Header('Authorization') required String token, @Path() required int mid, @Path() required int cid});

  @override
  @GET('/shelf')
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({@Header('Authorization') required String token, @Query('page') required int page});

  @override
  @GET('/shelf/{mid}')
  Future<Result<ShelfStatus>> checkShelfManga({@Header('Authorization') required String token, @Path() required int mid});

  @override
  @POST('/shelf/{mid}')
  Future<Result> addToShelf({@Header('Authorization') required String token, @Path() required int mid});

  @override
  @DELETE('/shelf/{mid}')
  Future<Result> removeFromShelf({@Header('Authorization') required String token, @Path() required int mid});

  @override
  @GET('/message')
  Future<Result<ResultPage<Message>>> getMessages();

  @override
  @GET('/message/latest')
  Future<Result<LatestMessage>> getLatestMessage();
}
