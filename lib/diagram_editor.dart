import 'package:flutter/material.dart';

// نموذج لبيانات "عقدة" (مربع نص، صورة، أو مهمة داخل المخطط)
class DiagramNode {
  String id;
  Offset position;
  String content;
  Color color;
  
  DiagramNode({
    required this.id,
    required this.position,
    required this.content,
    this.color = const Color(0xFFBB9AF7), // Venom Purple
  });
}

class DiagramEditor extends StatefulWidget {
  const DiagramEditor({Key? key}) : super(key: key);

  @override
  State<DiagramEditor> createState() => _DiagramEditorState();
}

class _DiagramEditorState extends State<DiagramEditor> {
  // قائمة العقد في المخطط
  final List<DiagramNode> _nodes = [];
  
  // للتحكم في التكبير والتحريك (Zoom & Pan)
  final TransformationController _transformController = TransformationController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // لكي تظهر خلفية Venom
      body: Stack(
        children: [
          // 1. مساحة الرسم اللانهائية
          InteractiveViewer(
            transformationController: _transformController,
            boundaryMargin: const EdgeInsets.all(double.infinity), // مساحة غير محدودة
            minScale: 0.1,
            maxScale: 5.0,
            child: Container(
              width: 5000, // مساحة افتراضية كبيرة
              height: 5000,
              // شبكة خلفية (Grid) خفيفة للمساعدة في الرسم
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/graphy.png"), // أو رسمها بـ CustomPaint
                  repeat: ImageRepeat.repeat,
                  opacity: 0.1,
                ),
              ),
              child: Stack(
                children: _nodes.map((node) {
                  return Positioned(
                    left: node.position.dx,
                    top: node.position.dy,
                    child: _buildDraggableNode(node),
                  );
                }).toList(),
              ),
            ),
          ),

          // 2. شريط الأدوات العائم (Floating Toolbar)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B26).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFBB9AF7).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolButton(Icons.check_box_outlined, "Add Task", () => _addNode("Task")),
                    const SizedBox(width: 15),
                    _toolButton(Icons.sticky_note_2_outlined, "Add Note", () => _addNode("Note")),
                    const SizedBox(width: 15),
                    _toolButton(Icons.image_outlined, "Add Image", () {}),
                    const SizedBox(width: 15),
                    _toolButton(Icons.alarm_add_rounded, "Set Alarm", () {}), // ربط المنبه
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // زر الأداة
  Widget _toolButton(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  // إضافة عقدة جديدة في منتصف الشاشة
  void _addNode(String type) {
    setState(() {
      _nodes.add(DiagramNode(
        id: DateTime.now().toString(),
        position: const Offset(2500, 2500), // في المنتصف الافتراضي
        content: "New $type",
      ));
    });
  }

  // بناء العقدة القابلة للسحب
  Widget _buildDraggableNode(DiagramNode node) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // تحديث الموقع عند السحب
          node.position += details.delta;
        });
      },
      child: Container(
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: node.color.withOpacity(0.2), // زجاجي
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: node.color),
          boxShadow: [
            BoxShadow(color: node.color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Center(
          child: Text(
            node.content,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}