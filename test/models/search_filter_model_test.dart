import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/models/search_filter_model.dart';

void main() {
  group('SearchFilterModel', () {
    test('default instance is marked as default with zero active filters', () {
      const filter = SearchFilterModel();
      expect(filter.isDefault, isTrue);
      expect(filter.activeFiltersCount, 0);
    });

    test('buildTargetQuery formats correct tags', () {
      const filter = SearchFilterModel(
        format: 'studio',
        genre: 'rock',
        region: 'ua',
      );
      final query = filter.buildTargetQuery('потап');
      expect(query, contains('official audio'));
      expect(query, contains('rock'));
      expect(query, contains('українська'));
      expect(filter.activeFiltersCount, 3);
    });

    test('matchesDuration respects filter ranges', () {
      const filterShort = SearchFilterModel(durationFilter: SearchDurationFilter.under5Min);
      expect(filterShort.matchesDuration(const Duration(minutes: 3)), isTrue);
      expect(filterShort.matchesDuration(const Duration(minutes: 6)), isFalse);

      const filterLong = SearchFilterModel(durationFilter: SearchDurationFilter.over10Min);
      expect(filterLong.matchesDuration(const Duration(minutes: 15)), isTrue);
      expect(filterLong.matchesDuration(const Duration(minutes: 4)), isFalse);
    });
  });
}
