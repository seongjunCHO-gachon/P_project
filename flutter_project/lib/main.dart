import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const PhotoGalleryPage(),
    );
  }
}

class PhotoGalleryPage extends StatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  _PhotoGalleryPageState createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  List<FileSystemEntity> _photos = [];
  List<FileSystemEntity> _filteredPhotos = [];
  String _searchQuery = '';

  Future<void> _pickFolder() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      final directory = Directory(directoryPath);

      // 선택된 폴더 내 모든 사진 파일 검색
      final photos = directory.listSync().where((file) {
        final extension = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
      }).toList();

      setState(() {
        _photos = photos;
        _filteredPhotos = _applySearchFilter(_photos, _searchQuery);
      });
    }
  }

  List<FileSystemEntity> _applySearchFilter(
      List<FileSystemEntity> photos, String query) {
    if (query.isEmpty) {
      return photos;
    }
    return photos.where((photo) {
      final fileName = photo.path.split(Platform.pathSeparator).last.toLowerCase();
      return fileName.contains(query.toLowerCase());
    }).toList();
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPhotos = _applySearchFilter(_photos, _searchQuery);
    });
  }

  void _sortPhotos({required bool ascending}) {
    setState(() {
      _photos.sort((a, b) {
        final aTime = File(a.path).lastModifiedSync();
        final bTime = File(b.path).lastModifiedSync();
        return ascending ? aTime.compareTo(bTime) : bTime.compareTo(aTime);
      });
      _filteredPhotos = _applySearchFilter(_photos, _searchQuery);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: '사진 검색',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // 텍스트 중앙 배치
          ),
          textAlign: TextAlign.start,
          onChanged: _updateSearchQuery,
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text('폴더 선택'),
              leading: const Icon(Icons.folder),
              onTap: () {
                _pickFolder();
                Navigator.pop(context); // 메뉴 닫기
              },
            ),
            ExpansionTile(
              title: const Text('정렬'),
              leading: const Icon(Icons.sort),
              children: [
                Column(
                  children: [
                    const Divider(),
                    ListTile(
                      title: const Text(
                        '최근 사진부터 정렬',
                        style: TextStyle(fontSize: 12.0), // 폰트 크기 축소
                      ),
                      leading: const Icon(Icons.arrow_downward),
                      onTap: () {
                        _sortPhotos(ascending: false); // 내림차순 정렬
                        Navigator.pop(context); // 메뉴 닫기
                      },
                    ),
                    const Divider(), // 경계선 추가
                    ListTile(
                      title: const Text(
                        '오래된 사진부터 정렬',
                        style: TextStyle(fontSize: 12.0), // 폰트 크기 축소
                      ),
                      leading: const Icon(Icons.arrow_upward),
                      onTap: () {
                        _sortPhotos(ascending: true); // 오름차순 정렬
                        Navigator.pop(context); // 메뉴 닫기
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _filteredPhotos.isEmpty
                ? const Center(child: Text('검색 결과가 없습니다.')) // 검색 결과가 없을 때 메시지 표시
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _filteredPhotos.length,
              itemBuilder: (context, index) {
                final photo = _filteredPhotos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenPhotoViewer(
                          photos: _filteredPhotos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: photo.path, // 고유 태그로 애니메이션 연결
                    child: Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenPhotoViewer extends StatefulWidget {
  final List<FileSystemEntity> photos;
  final int initialIndex;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  _FullScreenPhotoViewerState createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () {
          // 화면 탭 시 팝업 메뉴 표시
          _showOptionsMenu();
        },
        child: PageView.builder(
          controller: _pageController,
          physics: _disableSwipe
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return Center(
              child: Hero(
                tag: photo.path,
                child: InteractiveViewer(
                  panEnabled: true,
                  child: Image.file(
                    File(photo.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  String _getUniqueFileName(Directory directory, String fileName) {
    String uniqueFileName = fileName;
    int count = 1;

    // 파일 이름과 확장자 분리
    final nameWithoutExtension = fileName.split('.').first;
    final extension = fileName.split('.').last;

    // 중복된 파일 이름이 존재할 경우 새로운 이름 생성
    while (File('${directory.path}/$uniqueFileName').existsSync()) {
      uniqueFileName = '$nameWithoutExtension$count.$extension';
      count++;
    }

    return uniqueFileName;
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('사진 정보'),
                onTap: () {
                  Navigator.pop(context);
                  _showPhotoDetails(
                      widget.photos[_pageController.page!.toInt()]);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('저장'),
                onTap: () {
                  final currentPhotoPath = widget.photos[_pageController.page!.toInt()].path;
                  final photoFile = File(currentPhotoPath);
                  _savePhoto(photoFile); // 사진 복사 및 저장
                },
              ),
              ListTile(
                leading: const Icon(Icons.swipe),
                title: Text(
                    _disableSwipe ? '스와이프 활성화' : '스와이프 비활성화'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _disableSwipe = !_disableSwipe;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _disableSwipe = false; // 스와이프 비활성화 여부를 추적하는 변수

  void _showPhotoDetails(FileSystemEntity photo) {
    final file = File(photo.path);
    final size = file.lengthSync();
    final modifiedDate = file.lastModifiedSync();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('사진 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('파일 이름: ${file.path
                  .split(Platform.pathSeparator)
                  .last}'),
              Text('파일 크기: ${(size / 1024).toStringAsFixed(2)} KB'),
              Text('수정 날짜: $modifiedDate'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }    // 파일 선택
  void _savePhoto(File photoFile) async {
    // 저장 디렉토리 설정
    final directory = Directory('/storage/emulated/0/Download');
    if (!directory.existsSync()) {
      directory.createSync(); // 디렉토리가 없으면 생성
    }

    // 원본 파일 이름 가져오기
    final fileName = photoFile.path.split(Platform.pathSeparator).last;

    // 중복된 파일 이름 처리
    final uniqueFileName = _getUniqueFileName(directory, fileName);
    final newPath = '${directory.path}/$uniqueFileName';

    try {
      // 파일 복사
      await photoFile.copy(newPath);
      if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일이 저장되었습니다: $newPath')),
      );
    } }catch (e) {
      if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 저장 실패: $e')),
        );
      }
    }
  }
}

