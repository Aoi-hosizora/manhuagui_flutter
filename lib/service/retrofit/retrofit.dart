import 'package:dio/dio.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/author.dart';
import 'package:manhuagui_flutter/model/category.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/model/result.dart';
import 'package:retrofit/http.dart';

part 'retrofit.g.dart';

@RestApi(baseUrl: BASE_API_URL)
abstract class RestClient {
  factory RestClient(Dio dio, {String baseUrl}) = _RestClient;

  @GET('/manga')
  Future<Result<ResultPage<TinyMangaPage>>> getAllMangaPages({@Query('page') int page, @Query('limit') int limit});

  @GET('/manga/{mid}')
  Future<Result<MangaPage>> getMangaPage({@Path() int mid});

  @GET('/manga/{mid}/{cid}')
  Future<Result<MangaChapter>> getMangaChapter({@Path() int mid, @Path() int cid});

  @GET('/list/serial')
  Future<Result<MangaPageGroupList>> getHotSerialMangas();

  @GET('/list/finish')
  Future<Result<MangaPageGroupList>> getFinishedMangas();

  @GET('/list/latest')
  Future<Result<MangaPageGroupList>> getLatestMangas();

  @GET('/list/updated')
  Future<Result<ResultPage<TinyMangaPage>>> getRecentUpdatedMangas();

  @GET('/category/age')
  Future<Result<ResultPage<Category>>> getAges();

  @GET('/category/zone')
  Future<Result<ResultPage<Category>>> getZones();

  @GET('/category/genre')
  Future<Result<ResultPage<Category>>> getGenres();

  @GET('/category/genre/{genre}')
  Future<Result<ResultPage<TinyMangaPage>>> getGenreMangas({@Path() String genre, @Query('zone') String zone, @Query('age') String age, @Query('status') String status, @Query('page') int page, @Query('order') String order});

  @GET('/search/{keyword}')
  Future<Result<ResultPage<SmallMangaPage>>> searchMangas({@Path() String keyword, @Query('page') int page, @Query('order') String order});

  @GET('/author')
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors({@Query('genre') String genre, @Query('zone') String zone, @Query('age') String age, @Query('page') int page, @Query('order') String order});

  @GET('/author/{aid}')
  Future<Result<Author>> getAuthor({@Path() int aid});

  @GET('/author/{aid}/manga')
  Future<Result<ResultPage<SmallMangaPage>>> getAuthorMangas({@Path() int aid, @Query('page') int page, @Query('order') String order});
}
