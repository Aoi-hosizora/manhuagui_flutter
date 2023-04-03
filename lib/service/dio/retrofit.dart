import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/comment.dart';
import 'package:manhuagui_flutter/model/message.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:manhuagui_flutter/model/user.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/dio.dart';

part 'retrofit.g.dart';

@RestApi(baseUrl: BASE_API_URL)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET('/')
  Future<HttpResponse<dynamic>> ping();

  @GET('/manga')
  Future<Result<ResultPage<TinyManga>>> getAllMangas({@Query('page') required int page, @Query('order') required MangaOrder order, @Query('allow_cache') bool allowCache = false});

  @GET('/manga/{mid}')
  Future<Result<Manga>> getManga({@Path() required int mid, @Query('allow_cache') bool allowCache = false});

  @GET('/manga/{mid}/{cid}')
  Future<Result<MangaChapter>> getMangaChapter({@Path() required int mid, @Path() required int cid, @Query('allow_cache') bool allowCache = false});

  @GET('/manga/random')
  Future<Result<RandomMangaInfo>> getRandomManga({@Query('allow_cache') bool allowCache = false});

  @POST('/manga/{mid}/vote')
  Future<Result> voteManga({@Header('Authorization') required String token, @Path() required int mid, @Query('score') required int score});

  @GET('/list/serial')
  Future<Result<MangaGroupList>> getHotSerialMangas({@Query('allow_cache') bool allowCache = false});

  @GET('/list/finish')
  Future<Result<MangaGroupList>> getFinishedMangas({@Query('allow_cache') bool allowCache = false});

  @GET('/list/latest')
  Future<Result<MangaGroupList>> getLatestMangas({@Query('allow_cache') bool allowCache = false});

  @GET('/list/homepage')
  Future<Result<HomepageMangaGroupList>> getHomepageMangas({@Query('allow_cache') bool allowCache = false});

  @GET('/list/updated')
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({@Query('page') required int page, @Query('limit') int limit = 42, @Query('allow_cache') bool allowCache = false});

  @GET('/category')
  Future<Result<CategoryList>> getCategories({@Query('allow_cache') bool allowCache = false});

  @GET('/category/genre')
  Future<Result<ResultPage<Category>>> getGenres({@Query('allow_cache') bool allowCache = false});

  @GET('/category/zones')
  Future<Result<ResultPage<Category>>> getZones({@Query('allow_cache') bool allowCache = false});

  @GET('/category/ages')
  Future<Result<ResultPage<Category>>> getAges({@Query('allow_cache') bool allowCache = false});

  @GET('/category/genre/{genre}')
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({@Path() required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('status') required String status, @Query('page') required int page, @Query('order') required MangaOrder order, @Query('allow_cache') bool allowCache = false});

  @GET('/search')
  Future<Result<ResultPage<SmallManga>>> searchMangas({@Query('keyword') required String keyword, @Query('page') required int page, @Query('order') required MangaOrder order, @Query('allow_cache') bool allowCache = false});

  @GET('/author')
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({@Query('genre') required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('page') required int page, @Query('order') required AuthorOrder order, @Query('allow_cache') bool allowCache = false});

  @GET('/author/{aid}')
  Future<Result<Author>> getAuthor({@Path() required int aid, @Query('allow_cache') bool allowCache = false});

  @GET('/author/{aid}/manga')
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({@Path() required int aid, @Query('page') required int page, @Query('order') required MangaOrder order, @Query('allow_cache') bool allowCache = false});

  @GET('/rank/day')
  Future<Result<ResultPage<MangaRanking>>> getDayRanking({@Query('type') required String type, @Query('allow_cache') bool allowCache = false});

  @GET('/rank/week')
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({@Query('type') required String type, @Query('allow_cache') bool allowCache = false});

  @GET('/rank/month')
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({@Query('type') required String type, @Query('allow_cache') bool allowCache = false});

  @GET('/rank/total')
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({@Query('type') required String type, @Query('allow_cache') bool allowCache = false});

  @GET('/comment/manga/{mid}')
  Future<Result<ResultPage<Comment>>> getMangaComments({@Path() required int mid, @Query('page') required int page, @Query('allow_cache') bool allowCache = false});

  @POST('/comment/{cid}/like')
  Future<Result> likeComment({@Path() required int cid});

  @POST('/comment/manga/{mid}')
  Future<Result<AddedComment>> addComment({@Header('Authorization') required String token, @Path() required int mid, @Query('text') required String text});

  @POST('/comment/manga/{mid}/{cid}')
  Future<Result<AddedComment>> replyComment({@Header('Authorization') required String token, @Path() required int mid, @Path() required int cid, @Query('text') required String text});

  @POST('/user/check_login')
  Future<Result<LoginCheckResult>> checkUserLogin({@Header('Authorization') required String token});

  @GET('/user/info')
  Future<Result<User>> getUserInfo({@Header('Authorization') required String token, @Query('allow_cache') bool allowCache = false});

  @POST('/user/login')
  Future<Result<Token>> login({@Query('username') required String username, @Query('password') required String password});

  @POST('/user/manga/{mid}/{cid}')
  Future<Result> recordManga({@Header('Authorization') required String token, @Path() required int mid, @Path() required int cid});

  @GET('/shelf')
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({@Header('Authorization') required String token, @Query('page') required int page, @Query('allow_cache') bool allowCache = false});

  @GET('/shelf/{mid}')
  Future<Result<ShelfStatus>> checkShelfManga({@Header('Authorization') required String token, @Path() required int mid, @Query('allow_cache') bool allowCache = false});

  @POST('/shelf/{mid}')
  Future<Result> addToShelf({@Header('Authorization') required String token, @Path() required int mid});

  @DELETE('/shelf/{mid}')
  Future<Result> removeFromShelf({@Header('Authorization') required String token, @Path() required int mid});

  @GET('/message')
  Future<Result<ResultPage<Message>>> getMessages({@Query('allow_cache') bool allowCache = false});

  @GET('/message/latest')
  Future<Result<LatestMessage>> getLatestMessage({@Query('allow_cache') bool allowCache = false});
}
