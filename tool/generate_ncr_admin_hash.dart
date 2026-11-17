// import 'package:bcrypt/bcrypt.dart';

// void main() {
//   const password = 'welcome123';

//   final hash = BCrypt.hashpw(
//     password,
//     BCrypt.gensalt(),
//   );

//   print('');
//   print('==============================================');
//   print('NCR ADMIN PASSWORD HASH');
//   print('==============================================');
//   print(hash);
//   print('==============================================');
//   print('');
// }

 import 'package:bcrypt/bcrypt.dart';

  void main() {
  const password = 'welcome123';

  const storedHash = r'''$2a$10$ZM5fBM6ReQrK/tTuW0376ulQpyHvbalOjB7p2Z3PMpAW2EjtLwqcu''';

  print('Password: $password');
  print('Hash length: ${storedHash.length}');
  print('Hash prefix: ${storedHash.substring(0, 4)}');

  final result = BCrypt.checkpw(
  password,
  storedHash,
  );

  print('Password verification result: $result');
  }