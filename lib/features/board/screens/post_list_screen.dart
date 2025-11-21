import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//게시판 별 글 목록 화면
class PostListScreen extends StatelessWidget {

  final String boardId; // 어떤 게시판인지 구분 키 ( ex "자유게시판" or "free" )
  final String title;// 제목에 표시할 글자
  const PostListScreen({super.key, required this.boardId, required this.title});

  // 파이어스토어에서 데이터 읽기
  Future<List<Map<String, dynamic>>> _fetch() async {
    // posts 컬렉션에서 boardId가 일치하는 문서만,
    //createdAt 기준 최신순으로 가져옴
    final qs = await FirebaseFirestore.instance
        .collection('posts')
        .where('boardId', isEqualTo: boardId) // 특정 게시판만
        .orderBy('createdAt', descending: true) // 최신순 정렬
        .get();
    // 문서 ID(d.id)도 함께 맵에 섞어서 리스트로 변환ㅅ
    return qs.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  //눈으로 보이는 UI 빌드하는 코드
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 앱바: 가운데 정렬된 제목 표시
      appBar: AppBar(centerTitle: true, title: Text(title)),

      // 비동기 데이터(_fetch) 상태에 따라 다른 위젯을 보여주는 FutureBuilder
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetch(), // 조회 시작(Future)
        builder: (context, snap) {
          // 1) 로딩 중: 로딩 인디케이터 표시
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2) 에러 발생: 에러 메시지 표시(권한/인덱스/네트워크 등)
          if (snap.hasError) {
            return Center(child: Text('에러: ${snap.error}'));
          }

          // 3) 데이터 정상 수신
          final items = snap.data ?? [];

          // 3-1) 문서가 없으면 “글이 없습니다.” 표시
          if (items.isEmpty) {
            return const Center(child: Text('글이 없습니다.'));
          }
          // 3-2) 문서가 있으면 리스트로 렌더링
          return ListView.separated(
            itemCount: items.length, // 아이템 개수
            separatorBuilder: (_, __) => const Divider(height: 1), // 아이템 사이 구분선
            itemBuilder: (_, i) {
              final p = items[i]; // i번째 글 데이터(Map)

              return ListTile( // 제목 한 줄만, 넘치면 ... 처리
                title: Text(
                    p['title'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),

                // 본문 한 줄만, 넘치면 ... 처리
                subtitle: Text(p['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),

                // 항목 탭하면 나중에 상세 화면으로 이동할 예정
                onTap: () {
                  // TODO: post_detail_screen으로 이동
                  // Navigator.pushNamed(context, RouteNames.postDetail, arguments: p['id']);
                },
              );
            },
          );
        },
      ),
      // 우하단 “글 작성” 버튼: 눌렀을 때 작성 화면으로 이동하도록 연결 예정
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: post_editor_screen으로 이동
        },
        label: const Text('✍️ 게시글 작성하기'),
      ),
    );
  }
}
