import 'dart:convert';
import 'package:flutter/foundation.dart'; // Chứa kIsWeb để nhận diện đang chạy Web hay Mobile
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart'; // Thư viện Kéo - Thả

void main() => runApp(const AIImageScannerApp());

class AIImageScannerApp extends StatelessWidget {
  const AIImageScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Image Scanner',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Dùng Mảng Byte (Uint8List) thay cho File để chạy được trên Web
  Uint8List? _imageBytes; 
  String _result = "Hãy chọn hoặc Kéo Thả ảnh vào đây";
  bool _isLoading = false;
  bool _isDragging = false; // Hiệu ứng khi kéo file lơ lửng trên khung
  final picker = ImagePicker();

  // Tự động chuyển IP: Nếu là Web/Mac thì dùng localhost, Android ảo thì 10.0.2.2
  String get apiUrl {
    if (kIsWeb) return "http://127.0.0.1:8000/predict";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:8000/predict";
    return "http://127.0.0.1:8000/predict"; 
  }

  final List<String> sampleImages = [
    'assets/images/fake1.png',
    'assets/images/fake2.png',
    'assets/images/real01.png',
    'assets/images/real02.png',
  ];

  // Hàm chọn ảnh từ Thư viện
  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Đọc ra Byte
      setState(() {
        _imageBytes = bytes;
        _result = "Đã chọn ảnh, nhấn QUÉT để phân tích.";
      });
    }
  }

  // Hàm load ảnh từ thư mục Assets (Đã tối ưu: Không cần tạo file tạm)
  Future loadAssetAsBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      setState(() {
        _imageBytes = byteData.buffer.asUint8List();
        _result = "Đã tải ảnh mẫu, nhấn QUÉT để phân tích.";
      });
    } catch (e) {
      setState(() {
        _result = "Lỗi load ảnh mẫu: $e";
      });
    }
  }

  void showSampleImagesDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          height: 300,
          child: Column(
            children: [
              const Text("Chọn Ảnh Mẫu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: sampleImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        loadAssetAsBytes(sampleImages[index]);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          sampleImages[index],
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Hàm gửi ảnh lên Server bằng Byte
  Future scanImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _result = "Đang phân tích...";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      // Thay vì truyền Path, ta truyền thẳng mảng Byte lên Server
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        _imageBytes!, 
        filename: 'upload.jpg'
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);

        setState(() {
          if (data['status'] == 'success') {
            String label = data['label'];
            double conf = data['confidence'];
            _result = "Kết quả: $label\nĐộ chính xác: $conf%";
          } else {
            _result = "Lỗi từ Server!";
          }
        });
      }
    } catch (e) {
      setState(() {
        _result = "Lỗi kết nối Server ($apiUrl)\nHãy kiểm tra xem đã bật file api.py chưa.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Scanner 🕵️')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- TÍNH NĂNG KÉO THẢ TÍCH HỢP Ở ĐÂY ---
              DropTarget(
                onDragDone: (detail) async {
                  // Lấy file đầu tiên người dùng thả vào
                  final bytes = await detail.files.first.readAsBytes();
                  setState(() {
                    _imageBytes = bytes;
                    _result = "Đã nhận ảnh kéo thả, nhấn QUÉT ngay!";
                  });
                },
                onDragEntered: (detail) => setState(() => _isDragging = true),
                onDragExited: (detail) => setState(() => _isDragging = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 350,
                  width: 350,
                  decoration: BoxDecoration(
                    color: _isDragging ? Colors.purple.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(
                      color: _isDragging ? Colors.purple : Colors.grey, 
                      width: _isDragging ? 3 : 1
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  // Hiển thị ảnh bằng bộ nhớ (Memory)
                  child: _imageBytes == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Kéo Thả Ảnh Vào Đây", style: TextStyle(color: Colors.grey, fontSize: 16))
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: getImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Tải Lên"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: showSampleImagesDialog,
                    icon: const Icon(Icons.folder),
                    label: const Text("Ảnh Mẫu"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: 250,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : scanImage,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.document_scanner),
                  label: const Text("QUÉT AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}