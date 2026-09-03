/// Language configuration for the hyphenation algorithm.
///
/// Data is provided in TeX notation - compact and human readable.
/// Generate additional languages with `dart run tool/tex2data.dart <abbr>`
/// from the `tool/tex/hyph-<abbr>.tex` sources
/// (https://tug.org/tex-hyphen/).
abstract class LanguageConfig {
  const LanguageConfig();

  /// Patterns in TeX notation, e.g. `.аб3р`.
  /// A digit marks the inter-letter level between the surrounding letters.
  List<String> get patterns;

  /// Exceptions in TeX notation, e.g. `во-жд`.
  /// A `-` marks an allowed break point.
  List<String> get exceptions;
}
