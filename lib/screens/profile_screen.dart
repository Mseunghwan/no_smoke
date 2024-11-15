import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final int currentPoints;

  const ProfileScreen({Key? key, required this.currentPoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '프로필 화면',
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // 설정 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '프로필 정보',
              style: Theme.of(context).textTheme.headlineSmall, // headline5 -> headlineSmall
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/characters/basicSterling.png'),
              ),
              title: Text('사용자 이름'),
              subtitle: Text('사용자 이메일'),
            ),
            const SizedBox(height: 16),
            Divider(),
            ListTile(
              leading: Icon(Icons.timeline),
              title: Text('금연 일수'),
              subtitle: Text('10일째 성공 중!'),
            ),
            ListTile(
              leading: Icon(Icons.monetization_on),
              title: Text('절약한 금액'),
              subtitle: Text('₩50,000'),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('현재 포인트'),
              subtitle: Text('$currentPoints 포인트'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정 화면'),
      ),
      body: Center(
        child: Text('설정 화면 내용'),
      ),
    );
  }
}
