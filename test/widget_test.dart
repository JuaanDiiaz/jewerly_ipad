// Placeholder kept for CI stability — the real smoke tests moved to
// paged_list_view_test.dart. The app entry point needs dotenv + network
// initialization that flutter_test's fake HttpClient can't provide.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder', () {
    expect(1 + 1, 2);
  });
}
