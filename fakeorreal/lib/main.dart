import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  File? _image;
  String _result = "Hãy chọn một bức ảnh để phân tích";
  bool _isLoading = false;
  final picker = ImagePicker();

  // IP Của Server (Nhớ đổi nếu dùng máy thật)
  final String apiUrl = "http://10.0.2.2:8000/predict";

  // --- DANH SÁCH ẢNH MẪU TRONG THƯ MỤC ASSETS ---
  // Sửa tên file ở đây cho giống với tên file fen bỏ vào thư mục assets/images/
  // --- DANH SÁCH ẢNH MẪU TRONG THƯ MỤC ASSETS ---
  final List<String> sampleImages = [
    'assets/images/fake1.png',
    'assets/images/fake2.png',
    'assets/images/real01.png',
    'assets/images/real02.png',
  ];

  // Hàm chọn ảnh từ Thư viện Gallery
  Future getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = "Đã chọn ảnh từ thư viện, nhấn QUÉT để phân tích.";
      });
    }
  }

  // Hàm chuyển ảnh từ Assets thành File vật lý để gửi lên Server
  Future loadAssetAsFile(String assetPath) async {
    try {
      // 1. Đọc dữ liệu từ file gói trong app
      final byteData = await rootBundle.load(assetPath);
      // 2. Tìm thư mục tạm của điện thoại
      final tempDir = await getTemporaryDirectory();
      // 3. Tạo một file tạm và ghi dữ liệu vào
      final file = File('${tempDir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );

      setState(() {
        _image = file;
        _result = "Đã tải ảnh mẫu, nhấn QUÉT để phân tích.";
      });
    } catch (e) {
      setState(() {
        _result = "Lỗi load ảnh mẫu: $e";
      });
    }
  }

  // Bảng hiển thị danh sách ảnh mẫu để người dùng chọn
  void showSampleImagesDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(10),
          height: 300,
          child: Column(
            children: [
              const Text(
                "Chọn Ảnh Mẫu Cố Định",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 ảnh 1 hàng
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: sampleImages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Đóng bảng
                        loadAssetAsFile(
                          sampleImages[index],
                        ); // Load ảnh ra màn hình
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          sampleImages[index],
                          fit: BoxFit.cover,
                          cacheWidth: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                    Text(
                                      'Lỗi file',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  // Hàm gửi ảnh lên Server FastAPI (Giữ nguyên không đổi)
  Future scanImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _result = "Đang phân tích...";
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', _image!.path),
      );

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
        _result = "Lỗi kết nối Server! Vui lòng kiểm tra lại IP.";
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
              // Khung hiển thị ảnh
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _image == null
                    ? const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 20),

              // Hàng nút chọn ảnh
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: getImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Thư viện"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: showSampleImagesDialog,
                    icon: const Icon(Icons.folder),
                    label: const Text("Ảnh Mẫu"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Nút Quét to đùng ở dưới
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : scanImage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.document_scanner),
                  label: const Text(
                    "QUÉT ẢNH",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Text hiển thị kết quả
              Text(
                _result,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
