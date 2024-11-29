import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<AssetEntity> _photos = []; // 전체 사진 리스트
  List<AssetEntity> _filteredPhotos = []; // 검색 결과에 따른 사진 리스트
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<String>> _photoTags = {}; // 사진 ID와 태그 매핑
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    setState(() {
      _loading = true;
    });

    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.image,
      );

      if (albums.isNotEmpty) {
        // 비동기적으로 총 사진 개수 가져오기
        int totalPhotos = await albums[0].assetCountAsync;

        // 총 사진 개수만큼 사진 가져오기
        List<AssetEntity> photos = await albums[0].getAssetListRange(
          start: 0,
          end: totalPhotos,
        );

        setState(() {
          _photos = photos;
          _filteredPhotos = photos;
        });

        // 예제 태그 데이터 추가 (실제 구현 시 태그를 로드)
        for (var photo in photos) {
          _photoTags[photo.id] = ["nature", "city", "animal"]; // 예제 태그
        }
      }
    } else {
      PhotoManager.openSetting();
    }

    setState(() {
      _loading = false;
    });
  }

  void _searchPhotos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPhotos = _photos;
      } else {
        _filteredPhotos = _photos.where((photo) {
          List<String> tags = _photoTags[photo.id] ?? [];
          return tags.any((tag) => tag.contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _showFullScreenPhoto(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPhoto(file: file),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('갤러리 태그 검색'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPhotos,
              decoration: const InputDecoration(
                hintText: '태그로 검색',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(
                  child: Text(
                    '갤러리에 사진이 없습니다.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 한 행에 두 개의 사진
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: _filteredPhotos.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<File?>(
                      future: _filteredPhotos[index].file,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.data != null) {
                          return GestureDetector(
                            onTap: () => _showFullScreenPhoto(snapshot.data!),
                            child: Image.file(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class FullScreenPhoto extends StatelessWidget {
  final File file;

  const FullScreenPhoto({required this.file, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 화면 보기'),
      ),
      body: Center(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }
}
