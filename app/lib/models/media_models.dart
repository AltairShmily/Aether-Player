class MediaItem {
  final String id;
  final String name;
  final String type;
  final String overview;
  final double communityRating;
  final String officialRating;
  final List<String> genres;
  final int productionYear;
  final int runTimeTicks;
  final String dateCreated;
  final String? primaryImageTag;
  final String? backdropImageTag;
  final String seriesName;
  final int indexNumber;
  final int parentIndexNumber;
  final String seriesId;
  final String seasonId;
  final UserData? userData;

  MediaItem({
    required this.id,
    required this.name,
    required this.type,
    this.overview = '',
    this.communityRating = 0,
    this.officialRating = '',
    this.genres = const [],
    this.productionYear = 0,
    this.runTimeTicks = 0,
    this.dateCreated = '',
    this.primaryImageTag,
    this.backdropImageTag,
    this.seriesName = '',
    this.indexNumber = 0,
    this.parentIndexNumber = 0,
    this.seriesId = '',
    this.seasonId = '',
    this.userData,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    String? primaryTag;
    String? backdropTag;

    final imageTags = json['ImageTags'];
    if (imageTags is Map<String, dynamic>) {
      primaryTag = imageTags['Primary'] as String?;
    }

    final backdropTags = json['BackdropImageTags'];
    if (backdropTags is List && backdropTags.isNotEmpty) {
      backdropTag = backdropTags[0] as String?;
    }

    return MediaItem(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      type: json['Type'] as String? ?? '',
      overview: json['Overview'] as String? ?? '',
      communityRating: (json['CommunityRating'] as num?)?.toDouble() ?? 0,
      officialRating: json['OfficialRating'] as String? ?? '',
      genres: (json['Genres'] as List<dynamic>?)?.cast<String>() ?? [],
      productionYear: json['ProductionYear'] as int? ?? 0,
      runTimeTicks: json['RunTimeTicks'] as int? ?? 0,
      dateCreated: json['DateCreated'] as String? ?? '',
      primaryImageTag: primaryTag,
      backdropImageTag: backdropTag,
      seriesName: json['SeriesName'] as String? ?? '',
      indexNumber: json['IndexNumber'] as int? ?? 0,
      parentIndexNumber: json['ParentIndexNumber'] as int? ?? 0,
      seriesId: json['SeriesId'] as String? ?? '',
      seasonId: json['SeasonId'] as String? ?? '',
      userData: json['UserData'] != null ? UserData.fromJson(json['UserData'] as Map<String, dynamic>) : null,
    );
  }

  String get durationText {
    if (runTimeTicks == 0) return '';
    final minutes = (runTimeTicks / 10000000 / 60).round();
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  bool get hasPrimaryImage => primaryImageTag != null && primaryImageTag!.isNotEmpty;
  bool get hasBackdrop => backdropImageTag != null && backdropImageTag!.isNotEmpty;
  bool get isSeries => type == 'Series';
  bool get isMovie => type == 'Movie';
  bool get isEpisode => type == 'Episode';

  String get episodeLabel {
    if (parentIndexNumber > 0 || indexNumber > 0) {
      return 'S${parentIndexNumber.toString().padLeft(2, '0')}E${indexNumber.toString().padLeft(2, '0')}';
    }
    return '';
  }
}

class UserData {
  final int playbackPositionTicks;
  final int playCount;
  final bool isFavorite;
  final bool played;
  final double playedPercentage;

  UserData({
    this.playbackPositionTicks = 0,
    this.playCount = 0,
    this.isFavorite = false,
    this.played = false,
    this.playedPercentage = 0,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      playbackPositionTicks: json['PlaybackPositionTicks'] as int? ?? 0,
      playCount: json['PlayCount'] as int? ?? 0,
      isFavorite: json['IsFavorite'] as bool? ?? false,
      played: json['Played'] as bool? ?? false,
      playedPercentage: (json['PlayedPercentage'] as num?)?.toDouble() ?? 0,
    );
  }

  double get progressPercent {
    if (playedPercentage > 0) return playedPercentage / 100.0;
    return 0;
  }
}

class ItemListResponse {
  final List<MediaItem> items;
  final int totalRecordCount;

  ItemListResponse({
    required this.items,
    required this.totalRecordCount,
  });

  factory ItemListResponse.fromJson(Map<String, dynamic> json) {
    return ItemListResponse(
      items: (json['Items'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecordCount: json['TotalRecordCount'] as int? ?? 0,
    );
  }
}

class SearchHint {
  final String id;
  final String name;
  final String type;
  final String overview;
  final double communityRating;
  final int productionYear;
  final String? primaryImageTag;

  SearchHint({
    required this.id,
    required this.name,
    required this.type,
    this.overview = '',
    this.communityRating = 0,
    this.productionYear = 0,
    this.primaryImageTag,
  });

  factory SearchHint.fromJson(Map<String, dynamic> json) {
    return SearchHint(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      type: json['Type'] as String? ?? '',
      overview: json['Overview'] as String? ?? '',
      communityRating: (json['CommunityRating'] as num?)?.toDouble() ?? 0,
      productionYear: json['ProductionYear'] as int? ?? 0,
      primaryImageTag: json['PrimaryImageTag'] as String?,
    );
  }

  bool get hasImage => primaryImageTag != null && primaryImageTag!.isNotEmpty;
}

class SearchResult {
  final List<SearchHint> searchHints;
  final int totalRecordCount;

  SearchResult({
    required this.searchHints,
    required this.totalRecordCount,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      searchHints: (json['SearchHints'] as List<dynamic>?)
              ?.map((e) => SearchHint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRecordCount: json['TotalRecordCount'] as int? ?? 0,
    );
  }
}

class MediaStreamInfo {
  final List<MediaSource> mediaSources;

  MediaStreamInfo({required this.mediaSources});

  factory MediaStreamInfo.fromJson(Map<String, dynamic> json) {
    return MediaStreamInfo(
      mediaSources: (json['MediaSources'] as List<dynamic>?)
              ?.map((e) => MediaSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MediaSource {
  final String id;
  final String name;
  final String container;
  final int size;
  final int bitrate;
  final List<MediaStream> mediaStreams;

  MediaSource({
    required this.id,
    required this.name,
    this.container = '',
    this.size = 0,
    this.bitrate = 0,
    this.mediaStreams = const [],
  });

  factory MediaSource.fromJson(Map<String, dynamic> json) {
    return MediaSource(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      container: json['Container'] as String? ?? '',
      size: json['Size'] as int? ?? 0,
      bitrate: json['Bitrate'] as int? ?? 0,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
              ?.map((e) => MediaStream.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MediaStream {
  final String type;
  final String codec;
  final String language;
  final String displayTitle;
  final int width;
  final int height;
  final int bitRate;
  final String channelLayout;
  final int index;

  MediaStream({
    required this.type,
    this.codec = '',
    this.language = '',
    this.displayTitle = '',
    this.width = 0,
    this.height = 0,
    this.bitRate = 0,
    this.channelLayout = '',
    required this.index,
  });

  factory MediaStream.fromJson(Map<String, dynamic> json) {
    return MediaStream(
      type: json['Type'] as String? ?? '',
      codec: json['Codec'] as String? ?? '',
      language: json['Language'] as String? ?? '',
      displayTitle: json['DisplayTitle'] as String? ?? '',
      width: json['Width'] as int? ?? 0,
      height: json['Height'] as int? ?? 0,
      bitRate: json['BitRate'] as int? ?? 0,
      channelLayout: json['ChannelLayout'] as String? ?? '',
      index: json['Index'] as int? ?? 0,
    );
  }

  bool get isVideo => type == 'Video';
  bool get isAudio => type == 'Audio';
  bool get isSubtitle => type == 'Subtitle';

  String get resolution {
    if (width == 0 || height == 0) return '';
    if (height >= 2160) return '4K';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return '${width}x$height';
  }
}

class MediaFolder {
  final String id;
  final String name;
  final String collectionType;
  final String? primaryImageTag;

  MediaFolder({
    required this.id,
    required this.name,
    this.collectionType = '',
    this.primaryImageTag,
  });

  factory MediaFolder.fromJson(Map<String, dynamic> json) {
    String? tag;
    final imageTags = json['ImageTags'];
    if (imageTags is Map<String, dynamic>) {
      tag = imageTags['Primary'] as String?;
    }

    return MediaFolder(
      id: json['Id'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      collectionType: json['CollectionType'] as String? ?? '',
      primaryImageTag: tag,
    );
  }

  bool get hasImage => primaryImageTag != null && primaryImageTag!.isNotEmpty;

  String get itemType {
    switch (collectionType) {
      case 'movies':
        return 'Movie';
      case 'tvshows':
        return 'Series';
      case 'music':
        return 'Audio';
      default:
        return '';
    }
  }
}
