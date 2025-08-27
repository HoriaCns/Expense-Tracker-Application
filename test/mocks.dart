import 'package:mockito/annotations.dart';
import 'package:expense_tracker/api/appwrite_client.dart';

// This annotation tells the build_runner to generate a mock class for AppwriteClient.
@GenerateMocks([AppwriteClient])
void main() {}