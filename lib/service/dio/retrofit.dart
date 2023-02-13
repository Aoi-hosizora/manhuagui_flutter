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

part 'retrofit.g.dart';

@RestApi(baseUrl: BASE_API_URL)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET('/manga')
  Future<Result<ResultPage<TinyManga>>> getAllMangas({@Query('page') required int page, @Query('order') required MangaOrder order});

  @GET('/manga/{mid}')
  Future<Result<Manga>> getManga({@Path() required int mid});

  @GET('/manga/{mid}/{cid}')
  Future<Result<MangaChapter>> getMangaChapter({@Path() required int mid, @Path() required int cid});

  @GET('/manga/random')
  Future<Result<RandomMangaInfo>> getRandomManga();

  @GET('/list/serial')
  Future<Result<MangaGroupList>> getHotSerialMangas();

  @GET('/list/finish')
  Future<Result<MangaGroupList>> getFinishedMangas();

  @GET('/list/latest')
  Future<Result<MangaGroupList>> getLatestMangas();

  @GET('/list/homepage')
  Future<Result<HomepageMangaGroupList>> getHomepageMangas();

  @GET('/list/updated')
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas({@Query('page') required int page, @Query('limit') int limit = 42});

  @GET('/category')
  Future<Result<CategoryList>> getCategories();

  @GET('/category/genre')
  Future<Result<ResultPage<Category>>> getGenres();

  @GET('/category/zones')
  Future<Result<ResultPage<Category>>> getZones();

  @GET('/category/ages')
  Future<Result<ResultPage<Category>>> getAges();

  @GET('/category/genre/{genre}')
  Future<Result<ResultPage<TinyManga>>> getGenreMangas({@Path() required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('status') required String status, @Query('page') required int page, @Query('order') required MangaOrder order});

  @GET('/search/{keyword}')
  Future<Result<ResultPage<SmallManga>>> searchMangas({@Path() required String keyword, @Query('page') required int page, @Query('order') required MangaOrder order});

  @GET('/author')
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({@Query('genre') required String genre, @Query('zone') required String zone, @Query('age') required String age, @Query('page') required int page, @Query('order') required AuthorOrder order});

  @GET('/author/{aid}')
  Future<Result<Author>> getAuthor({@Path() required int aid});

  @GET('/author/{aid}/manga')
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas({@Path() required int aid, @Query('page') required int page, @Query('order') required MangaOrder order});

  @GET('/rank/day')
  Future<Result<ResultPage<MangaRanking>>> getDayRanking({@Query('type') required String type});

  @GET('/rank/week')
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking({@Query('type') required String type});

  @GET('/rank/month')
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking({@Query('type') required String type});

  @GET('/rank/total')
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking({@Query('type') required String type});

  @GET('/comment/manga/{mid}')
  Future<Result<ResultPage<Comment>>> getMangaComments({@Path() required int mid, @Query('page') required int page});

  @POST('/user/check_login')
  Future<Result<LoginCheckResult>> checkUserLogin({@Header('Authorization') required String token});

  @GET('/user/info')
  Future<Result<User>> getUserInfo({@Header('Authorization') required String token});

  @POST('/user/login')
  Future<Result<Token>> login({@Query('username') required String username, @Query('password') required String password});

  @POST('/user/manga/{mid}/{cid}')
  Future<Result> recordManga({@Header('Authorization') required String token, @Path() required int mid, @Path() required int cid});

  @GET('/shelf')
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas({@Header('Authorization') required String token, @Query('page') required int page});

  @GET('/shelf/{mid}')
  Future<Result<ShelfStatus>> checkShelfManga({@Header('Authorization') required String token, @Path() required int mid});

  @POST('/shelf/{mid}')
  Future<Result> addToShelf({@Header('Authorization') required String token, @Path() required int mid});

  @DELETE('/shelf/{mid}')
  Future<Result> removeFromShelf({@Header('Authorization') required String token, @Path() required int mid});

  @GET('/message')
  Future<Result<ResultPage<Message>>> getMessages();

  @GET('/message/latest')
  Future<Result<LatestMessage>> getLatestMessage();
}
