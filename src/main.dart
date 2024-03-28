import "package:bluesky/bluesky.dart";
import "package:postgres/postgres.dart";
import "package:http/http.dart" as http;

Future<void> main() async {
	print("Started running");

	final db = await Connection.open(Endpoint(
		host: "localhost",
		database: "postgres",
		username: "user",
		password: "pass",
	),
		settings: ConnectionSettings(sslMode: SslMode.disable)
	);

	print("Connected to database");
	
	await db.execute("CREATE TABLE IF NOT EXISTS posts ("
		"id SERIAL PRIMARY KEY,"
		"author TEXT,"
		"content TEXT,"
		"link TEXT,"
		"timestamp TEXT)");

	
	const List politicalTerms = ["trump", "biden", "republic", "democrat", "election", "vote", "president", "senate", "congress", "politics", "political", "party"];
	
	final bluesky = Bluesky.anonymous(); // Authentication is not required.
	final subscription = await bluesky.sync.subscribeRepos();

	final repoCommitAdaptor = RepoCommitAdaptor(
		onCreatePost: (post) async {
			for (final word in politicalTerms) {
				if (post.record.text.toLowerCase().contains(word)) {
					print(post.record.text);
					await db.execute(
					Sql.named("INSERT INTO posts (author, content, link, timestamp) VALUES (@author, @content, @link, @timestamp)"),
					parameters: {
						"author": post.author,
						"content": post.record.text,
						"link": post.uri.href,
						"timestamp": post.record.createdAt.toUtc().millisecondsSinceEpoch.toString(),
					});
					break;
				}
			}
		},
	);

	await for (final event in subscription.data.stream) {
		event.when(
			commit: repoCommitAdaptor.execute,
			handle: print,//(x) {},
			migrate: print,//(x) {},
			tombstone: print,//(x) {},
			info: print,//(x) {},
			unknown: print,//(x) {},
		);
	}
}