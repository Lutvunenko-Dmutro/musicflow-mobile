enum SearchSortBy {
  relevance,
  views,
  newest,
}

enum SearchDurationFilter {
  any,
  under5Min,
  under10Min,
  over10Min,
}

class SearchFilterModel {
  final String region; // 'all', 'ua', 'global', 'kpop', 'latino'
  final String genre; // 'all', 'rock', 'pop', 'electronic', 'rap', 'lofi'
  final String format; // 'all', 'studio', 'clip', 'live', 'acoustic', 'remix'
  final SearchDurationFilter durationFilter;
  final SearchSortBy sortBy;

  const SearchFilterModel({
    this.region = 'all',
    this.genre = 'all',
    this.format = 'all',
    this.durationFilter = SearchDurationFilter.any,
    this.sortBy = SearchSortBy.relevance,
  });

  bool get isDefault =>
      region == 'all' &&
      genre == 'all' &&
      format == 'all' &&
      durationFilter == SearchDurationFilter.any &&
      sortBy == SearchSortBy.relevance;

  int get activeFiltersCount {
    int count = 0;
    if (region != 'all') count++;
    if (genre != 'all') count++;
    if (format != 'all') count++;
    if (durationFilter != SearchDurationFilter.any) count++;
    if (sortBy != SearchSortBy.relevance) count++;
    return count;
  }

  SearchFilterModel copyWith({
    String? region,
    String? genre,
    String? format,
    SearchDurationFilter? durationFilter,
    SearchSortBy? sortBy,
  }) {
    return SearchFilterModel(
      region: region ?? this.region,
      genre: genre ?? this.genre,
      format: format ?? this.format,
      durationFilter: durationFilter ?? this.durationFilter,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  String buildTargetQuery(String baseQuery) {
    final tags = <String>[];

    // Format tags
    if (format == 'studio') {
      tags.add('official audio');
    } else if (format == 'clip') {
      tags.add('official music video');
    } else if (format == 'live') {
      tags.add('live');
    } else if (format == 'acoustic') {
      tags.add('acoustic');
    } else if (format == 'remix') {
      tags.add('remix');
    }

    // Genre tags
    if (genre != 'all') {
      tags.add(genre);
    }

    // Region tags
    if (region == 'ua') {
      tags.add('українська');
    } else if (region == 'global') {
      tags.add('english');
    } else if (region == 'ru') {
      tags.add('русская');
    } else if (region == 'kpop') {
      tags.add('k-pop');
    } else if (region == 'latino') {
      tags.add('latino');
    }

    if (tags.isEmpty) {
      return baseQuery;
    }

    return '$baseQuery ${tags.join(" ")}';
  }

  bool matchesDuration(Duration duration) {
    switch (durationFilter) {
      case SearchDurationFilter.any:
        return true;
      case SearchDurationFilter.under5Min:
        return duration.inMinutes < 5;
      case SearchDurationFilter.under10Min:
        return duration.inMinutes <= 10;
      case SearchDurationFilter.over10Min:
        return duration.inMinutes >= 10;
    }
  }
}
