/*
  These users are only used for testing
  They can be found in the test database
*/

class _User {
  const _User({
    required this.username,
    required this.email,
    required this.password,
    required this.userID,
    required this.bio,
    required this.displayUsername,
    required this.profilePicPath,
    required this.profilePicUrl,
  });

  final String username;
  final String email;
  final String password;
  final String userID;
  final String bio;
  final String displayUsername;
  final String profilePicPath;
  final String profilePicUrl;
}

final user1 = _User(
  username: 'test',
  email: 'test@exmaple.com',
  password: 'asdasd',
  userID: 'b727fd96-f618-4121-b875-e5fb74539034',
  bio: 'test',
  displayUsername: 'testname',
  profilePicPath: 'ed10c995-6a88-44fe-a1a8-4149857afd1e.jpg',
  profilePicUrl: 'http://127.0.0.1:9199/v0/b/gym-buddy-9ab39.firebasestorage.app/o/profile_pics%2Fb727fd96-f618-4121-b875-e5fb74539034%2Fed10c995-6a88-44fe-a1a8-4149857afd1e.jpg?alt=media&token=707528b9-0af3-4989-9cd0-a02c047844d7'
);

final user2 = _User(
  username: 'test3',
  email: 'asd@test.com',
  password: 'asdasd',
  userID: '4f307ff7-f201-4732-93a9-72810a52e194',
  bio: '',
  displayUsername: 'test3',
  profilePicPath: '',
  profilePicUrl: ''
);