// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'retrofit.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _RestClient implements RestClient {
  _RestClient(this._dio, {this.baseUrl}) {
    baseUrl ??= 'https://api-manhuagui.aoihosizora.top/v1/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<HttpResponse<dynamic>> ping() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch(_setStreamType<HttpResponse<dynamic>>(
        Options(method: 'GET', headers: _headers, extra: _extra)
            .compose(_dio.options, '/',
                queryParameters: queryParameters, data: _data)
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = _result.data;
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  @override
  Future<Result<ResultPage<TinyManga>>> getAllMangas(
      {required page, required order, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'order': order.toJson(),
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<TinyManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/manga',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<TinyManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<TinyManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => TinyManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<Manga>> getManga({required mid, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<Manga>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/manga/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<Manga>.fromJson(
      _result.data!,
      (json) => Manga.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<MangaChapter>> getMangaChapter(
      {required mid, required cid, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<MangaChapter>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/manga/${mid}/${cid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<MangaChapter>.fromJson(
      _result.data!,
      (json) => MangaChapter.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<RandomMangaInfo>> getRandomManga({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<RandomMangaInfo>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/manga/random',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<RandomMangaInfo>.fromJson(
      _result.data!,
      (json) => RandomMangaInfo.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<dynamic>> voteManga(
      {required token, required mid, required score}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'score': score};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<dynamic>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/manga/${mid}/vote',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<dynamic>.fromJson(
      _result.data!,
      (json) => json as dynamic,
    );
    return value;
  }

  @override
  Future<Result<MangaGroupList>> getHotSerialMangas(
      {allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<MangaGroupList>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/list/serial',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<MangaGroupList>.fromJson(
      _result.data!,
      (json) => MangaGroupList.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<MangaGroupList>> getFinishedMangas({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<MangaGroupList>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/list/finish',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<MangaGroupList>.fromJson(
      _result.data!,
      (json) => MangaGroupList.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<MangaGroupList>> getLatestMangas({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<MangaGroupList>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/list/latest',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<MangaGroupList>.fromJson(
      _result.data!,
      (json) => MangaGroupList.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<HomepageMangaGroupList>> getHomepageMangas(
      {allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<HomepageMangaGroupList>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/list/homepage',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<HomepageMangaGroupList>.fromJson(
      _result.data!,
      (json) => HomepageMangaGroupList.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<TinyManga>>> getRecentUpdatedMangas(
      {required page, limit = 42, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'limit': limit,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<TinyManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/list/updated',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<TinyManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<TinyManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => TinyManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<CategoryList>> getCategories({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<CategoryList>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/category',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<CategoryList>.fromJson(
      _result.data!,
      (json) => CategoryList.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getGenres({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<Category>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/category/genre',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<Category>>.fromJson(
      _result.data!,
      (json) => ResultPage<Category>.fromJson(
        json as Map<String, dynamic>,
        (json) => Category.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getZones({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<Category>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/category/zones',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<Category>>.fromJson(
      _result.data!,
      (json) => ResultPage<Category>.fromJson(
        json as Map<String, dynamic>,
        (json) => Category.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<Category>>> getAges({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<Category>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/category/ages',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<Category>>.fromJson(
      _result.data!,
      (json) => ResultPage<Category>.fromJson(
        json as Map<String, dynamic>,
        (json) => Category.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<TinyManga>>> getGenreMangas(
      {required genre,
      required zone,
      required age,
      required status,
      required page,
      required order,
      allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'zone': zone,
      r'age': age,
      r'status': status,
      r'page': page,
      r'order': order.toJson(),
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<TinyManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/category/genre/${genre}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<TinyManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<TinyManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => TinyManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<SmallManga>>> searchMangas(
      {required keyword,
      required page,
      required order,
      allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'keyword': keyword,
      r'page': page,
      r'order': order.toJson(),
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<SmallManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/search',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<SmallManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<SmallManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => SmallManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<SmallAuthor>>> getAllAuthors(
      {required genre,
      required zone,
      required age,
      required page,
      required order,
      allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'genre': genre,
      r'zone': zone,
      r'age': age,
      r'page': page,
      r'order': order.toJson(),
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<SmallAuthor>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/author',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<SmallAuthor>>.fromJson(
      _result.data!,
      (json) => ResultPage<SmallAuthor>.fromJson(
        json as Map<String, dynamic>,
        (json) => SmallAuthor.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<Author>> getAuthor({required aid, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<Author>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/author/${aid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<Author>.fromJson(
      _result.data!,
      (json) => Author.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<SmallManga>>> getAuthorMangas(
      {required aid, required page, required order, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'order': order.toJson(),
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<SmallManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/author/${aid}/manga',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<SmallManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<SmallManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => SmallManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getDayRanking(
      {required type, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'type': type,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<MangaRanking>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/rank/day',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<MangaRanking>>.fromJson(
      _result.data!,
      (json) => ResultPage<MangaRanking>.fromJson(
        json as Map<String, dynamic>,
        (json) => MangaRanking.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getWeekRanking(
      {required type, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'type': type,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<MangaRanking>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/rank/week',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<MangaRanking>>.fromJson(
      _result.data!,
      (json) => ResultPage<MangaRanking>.fromJson(
        json as Map<String, dynamic>,
        (json) => MangaRanking.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getMonthRanking(
      {required type, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'type': type,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<MangaRanking>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/rank/month',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<MangaRanking>>.fromJson(
      _result.data!,
      (json) => ResultPage<MangaRanking>.fromJson(
        json as Map<String, dynamic>,
        (json) => MangaRanking.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<MangaRanking>>> getTotalRanking(
      {required type, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'type': type,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<MangaRanking>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/rank/total',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<MangaRanking>>.fromJson(
      _result.data!,
      (json) => ResultPage<MangaRanking>.fromJson(
        json as Map<String, dynamic>,
        (json) => MangaRanking.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ResultPage<Comment>>> getMangaComments(
      {required mid, required page, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<Comment>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/comment/manga/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<Comment>>.fromJson(
      _result.data!,
      (json) => ResultPage<Comment>.fromJson(
        json as Map<String, dynamic>,
        (json) => Comment.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<dynamic>> likeComment({required cid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<dynamic>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/comment/${cid}/like',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<dynamic>.fromJson(
      _result.data!,
      (json) => json as dynamic,
    );
    return value;
  }

  @override
  Future<Result<AddedComment>> addComment(
      {required token, required mid, required text}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'text': text};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<AddedComment>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/comment/manga/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<AddedComment>.fromJson(
      _result.data!,
      (json) => AddedComment.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<AddedComment>> replyComment(
      {required token, required mid, required cid, required text}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'text': text};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<AddedComment>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/comment/manga/${mid}/${cid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<AddedComment>.fromJson(
      _result.data!,
      (json) => AddedComment.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<LoginCheckResult>> checkUserLogin({required token}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<LoginCheckResult>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/user/check_login',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<LoginCheckResult>.fromJson(
      _result.data!,
      (json) => LoginCheckResult.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<User>> getUserInfo({required token, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<User>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/user/info',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<User>.fromJson(
      _result.data!,
      (json) => User.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<Token>> login({required username, required password}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'username': username,
      r'password': password
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<Token>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/user/login',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<Token>.fromJson(
      _result.data!,
      (json) => Token.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<dynamic>> recordManga(
      {required token, required mid, required cid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<dynamic>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/user/manga/${mid}/${cid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<dynamic>.fromJson(
      _result.data!,
      (json) => json as dynamic,
    );
    return value;
  }

  @override
  Future<Result<ResultPage<ShelfManga>>> getShelfMangas(
      {required token, required page, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'page': page,
      r'allow_cache': allowCache
    };
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<ShelfManga>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/shelf',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<ShelfManga>>.fromJson(
      _result.data!,
      (json) => ResultPage<ShelfManga>.fromJson(
        json as Map<String, dynamic>,
        (json) => ShelfManga.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<ShelfStatus>> checkShelfManga(
      {required token, required mid, allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ShelfStatus>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/shelf/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ShelfStatus>.fromJson(
      _result.data!,
      (json) => ShelfStatus.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  @override
  Future<Result<dynamic>> addToShelf({required token, required mid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<dynamic>>(
            Options(method: 'POST', headers: _headers, extra: _extra)
                .compose(_dio.options, '/shelf/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<dynamic>.fromJson(
      _result.data!,
      (json) => json as dynamic,
    );
    return value;
  }

  @override
  Future<Result<dynamic>> removeFromShelf(
      {required token, required mid}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Authorization': token};
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<dynamic>>(
            Options(method: 'DELETE', headers: _headers, extra: _extra)
                .compose(_dio.options, '/shelf/${mid}',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<dynamic>.fromJson(
      _result.data!,
      (json) => json as dynamic,
    );
    return value;
  }

  @override
  Future<Result<ResultPage<Message>>> getMessages({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<ResultPage<Message>>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/message',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<ResultPage<Message>>.fromJson(
      _result.data!,
      (json) => ResultPage<Message>.fromJson(
        json as Map<String, dynamic>,
        (json) => Message.fromJson(json as Map<String, dynamic>),
      ),
    );
    return value;
  }

  @override
  Future<Result<LatestMessage>> getLatestMessage({allowCache = false}) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'allow_cache': allowCache};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<Result<LatestMessage>>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options, '/message/latest',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = Result<LatestMessage>.fromJson(
      _result.data!,
      (json) => LatestMessage.fromJson(json as Map<String, dynamic>),
    );
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
