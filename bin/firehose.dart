import 'package:bluesky/bluesky.dart';

Future<void> main() async {
  const List politicalTerms = ["trump", "biden", "republican", "democrat"];
  // Authentication is not required.
  final bluesky = Bluesky.anonymous();
  final subscription = await bluesky.sync.subscribeRepos();

  // Use `RepoCommitAdaptor`.
  final repoCommitAdaptor = RepoCommitAdaptor(
      // Occurs only when post record is created.
      onCreatePost: (data) {
    final String postContent = data.record.text;
    for (final word in politicalTerms) {
      if (postContent.toLowerCase().contains(word)) {
        processWithAI(author: data.author, postContent: postContent);
        break;
      }
    }
  });

  await for (final event in subscription.data.stream) {
    event.when(
      commit: repoCommitAdaptor.execute, // Execute like this.
      handle: print,
      migrate: print,
      tombstone: print,
      info: print,
      unknown: print,
    );
  }
}

void processWithAI({String? postContent, String? author}) {
  //implement AI logic
  print(postContent);
  print(author);
}
