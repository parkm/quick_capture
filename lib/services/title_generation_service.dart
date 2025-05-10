import 'package:intl/intl.dart';

class TitleGenerationService {
  /// Generates a title for a note based on its content
  /// Format: "YYYY-MM-DD Summary of note content"
  String generateTitle(String content) {
    // Get today's date in ISO format (YYYY-MM-DD)
    final dateFormat = DateFormat('yyyy-MM-dd');
    final todaysDate = dateFormat.format(DateTime.now());

    // Generate summary from the content using SumBasic algorithm
    final summary = _generateSummaryWithSumBasic(content);

    // Combine date and summary
    return '$todaysDate $summary';
  }

  /// Creates a short summary from the note content using the SumBasic algorithm
  String _generateSummaryWithSumBasic(String content) {
    // Trim whitespace
    final trimmedContent = content.trim();

    // If empty, return a generic title
    if (trimmedContent.isEmpty) {
      return 'Empty note';
    }

    // Split content into sentences
    final sentences = _splitIntoSentences(trimmedContent);
    if (sentences.isEmpty) return 'Empty note';

    // If there's only one sentence, use a simplified approach
    if (sentences.length == 1) {
      return _sanitizeForFilename(_shortenText(sentences.first, 50));
    }

    // Tokenize and clean each sentence
    final tokenizedSentences = sentences.map(_tokenize).toList();

    // Calculate word probabilities (frequency)
    final wordProbabilities = _calculateWordProbabilities(tokenizedSentences);

    // Score each sentence using word probabilities
    final scoredSentences = _scoreSentences(sentences, tokenizedSentences, wordProbabilities);

    // Select the highest scored sentence as the summary
    final highestScoredSentence = _selectHighestScoredSentence(scoredSentences);

    // Shorten if necessary and sanitize for filename use
    return _sanitizeForFilename(_shortenText(highestScoredSentence, 50));
  }

  /// Sanitizes a string to be safely used as a filename across platforms
  String _sanitizeForFilename(String text) {
    // Remove characters that are problematic in filenames across platforms
    // This covers Windows, macOS, Linux, and Android restrictions
    return text
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '') // Remove invalid chars
        .replaceAll(RegExp(r'\s+'), ' ')                // Normalize whitespace
        .trim();
  }

  /// Splits text into sentences
  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitting based on common punctuation
    final sentenceDelimiters = RegExp(r'(?<=[.!?])\s+');
    final sentences = text.split(sentenceDelimiters)
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return sentences;
  }

  /// Tokenizes a sentence into words, removing punctuation and converting to lowercase
  List<String> _tokenize(String sentence) {
    // Remove punctuation and convert to lowercase
    final cleanedSentence = sentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    // Split into words and remove stop words
    final words = cleanedSentence.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !_isStopWord(word))
        .toList();

    return words;
  }

  /// Calculates the probability (frequency) of each word in the document
  Map<String, double> _calculateWordProbabilities(List<List<String>> tokenizedSentences) {
    // Count word occurrences
    final wordCounts = <String, int>{};
    int totalWords = 0;

    for (var sentence in tokenizedSentences) {
      for (var word in sentence) {
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
        totalWords++;
      }
    }

    // Calculate probability for each word
    final wordProbabilities = <String, double>{};
    if (totalWords > 0) {
      wordCounts.forEach((word, count) {
        wordProbabilities[word] = count / totalWords;
      });
    }

    return wordProbabilities;
  }

  /// Scores each sentence based on the average probability of its words
  List<Map<String, dynamic>> _scoreSentences(
      List<String> originalSentences,
      List<List<String>> tokenizedSentences,
      Map<String, double> wordProbabilities) {

    final scoredSentences = <Map<String, dynamic>>[];

    for (int i = 0; i < tokenizedSentences.length; i++) {
      final words = tokenizedSentences[i];
      if (words.isEmpty) continue;

      // Calculate sentence score (average word probability)
      double sentenceScore = 0;
      for (var word in words) {
        sentenceScore += wordProbabilities[word] ?? 0;
      }
      sentenceScore /= words.length;

      scoredSentences.add({
        'sentence': originalSentences[i],
        'score': sentenceScore,
        'position': i, // Keep track of original position
      });
    }

    // Sort by score in descending order
    scoredSentences.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return scoredSentences;
  }

  /// Selects the highest scored sentence
  String _selectHighestScoredSentence(List<Map<String, dynamic>> scoredSentences) {
    if (scoredSentences.isEmpty) return 'Empty note';

    // Return the highest scored sentence
    return scoredSentences.first['sentence'] as String;
  }

  /// Shortens text to specified length if necessary
  String _shortenText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Checks if a word is a stop word (common words with little meaning)
  bool _isStopWord(String word) {
    const stopWords = {
      'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'with',
      'by', 'about', 'as', 'of', 'from', 'is', 'are', 'was', 'were', 'be', 'been',
      'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'shall',
      'should', 'can', 'could', 'may', 'might', 'must', 'this', 'that', 'these',
      'those', 'it', 'its', 'i', 'my', 'me', 'mine', 'you', 'your', 'yours', 'he',
      'him', 'his', 'she', 'her', 'hers', 'we', 'us', 'our', 'ours', 'they', 'them',
      'their', 'theirs'
    };

    return stopWords.contains(word);
  }
}