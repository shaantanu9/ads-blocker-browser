import 'package:flutter_test/flutter_test.dart';
import 'package:open_adblock_browser/ad_block.dart';

void main() {
  test('host rules match a network host and subdomains only', () {
    expect(isBlockedHost('doubleclick.net'), isTrue);
    expect(isBlockedHost('securepubads.g.doubleclick.net'), isTrue);
    expect(isBlockedHost('notdoubleclick.net'), isFalse);
    expect(isBlockedHost('comic.example'), isFalse);
  });

  test('the URL pattern covers a whole ad URL without covering lookalikes', () {
    final rule = RegExp(hostPattern('doubleclick.net'));
    expect(
      rule.hasMatch('https://securepubads.g.doubleclick.net/tag.js'),
      isTrue,
    );
    expect(rule.hasMatch('https://notdoubleclick.net/tag.js'), isFalse);
    expect(
      rule.hasMatch('https://comic.example/?network=doubleclick.net'),
      isFalse,
    );
  });

  test('cosmetic script has no external network or executable update path', () {
    final script = cosmeticHideScript();
    expect(script, contains('display: none !important'));
    expect(script, isNot(contains('fetch(')));
    expect(script, isNot(contains('eval(')));
  });
}
