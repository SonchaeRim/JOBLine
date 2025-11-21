//필드: uid, email, displayName, photoUrl, mainCommunityId 등 정의

class UserModel{
  //체크리스트 필드
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String mainCommunituId;

  //2. 필수로 받아야하는 값
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.mainCommunituId
  });
}