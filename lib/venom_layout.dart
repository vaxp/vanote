import 'dart:ui'; // مهم للـ ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/page_manager.dart';

// 1. هذا هو الـ Layout الرئيسي الذي ستستخدمه في تطبيقك
class VenomScaffold extends StatefulWidget {
  final Widget body; // محتوى الصفحة (الإعدادات)
  final String title;
  final String? selectedCategory;
  final bool showBackButton;
  final bool showAddButton;

  const VenomScaffold({
    Key? key,
    required this.body,
    this.title = "",
    this.selectedCategory,
    this.showBackButton = false,
    this.showAddButton = false,

  }) : super(key: key);

  @override
  State<VenomScaffold> createState() => _VenomScaffoldState();
}

class _VenomScaffoldState extends State<VenomScaffold> {
  // متغير الحالة للتحكم في الضبابية
  bool _isCinematicBlurActive = false;

  void _setBlur(bool active) {
    if (_isCinematicBlurActive != active && mounted) {
      setState(() {
        _isCinematicBlurActive = active;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(100, 0, 0, 0),
      body: Stack(
        children: [
          // --- الطبقة 1: محتوى التطبيق ---
          // Use instant blur toggle (no animation) for responsiveness
          RepaintBoundary(
            child: _isCinematicBlurActive
                ? ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      margin: const EdgeInsets.only(top: 40),
                      child: widget.body,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(top: 40),
                    child: widget.body,
                  ),
          ),

          // --- الطبقة 2: شريط العنوان (فوق الكل) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: VenomAppbar(
              title: widget.title,
              selectedCategory: widget.selectedCategory,
              showBackButton: widget.showBackButton,
              showAddButton: widget.showAddButton,
              // تمرير دالة للتحكم في البلور عند لمس الأزرار
              onHoverEnter: () => _setBlur(true),
              onHoverExit: () => _setBlur(false),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. شريط العنوان المعدل (يرسل إشارات الهوفر)
class VenomAppbar extends StatelessWidget {
  final String title;
  final String? selectedCategory;
  final bool showBackButton;
  final bool showAddButton;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  const VenomAppbar({
    Key? key,
    required this.title,
    this.selectedCategory,
    this.showBackButton = false,
    this.showAddButton = false,
    required this.onHoverEnter,
    required this.onHoverExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) async {
            await windowManager.startDragging();
          },
          child: Container(
            height: 40,
            alignment: Alignment.centerRight,
            // خلفية نصف شفافة للشريط نفسه
            // color: const Color.fromARGB(100, 0, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                if (showBackButton)
                GestureDetector(
                  onTap: () {
                    final pageManager = Provider.of<PageManager>(context, listen: false);
                    pageManager.goBack();
                  },
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 155),
                if (showAddButton)
                  GestureDetector(
                    onTap: () => _addNewTask(context),
                    child: const Icon(Icons.add),
                  ),

             const Spacer(),
                // مجموعة الأزرار
                // نستخدم MouseRegion واحد كبير حول الأزرار الثلاثة
                // لضمان استمرار البلور عند التنقل بين زر وآخر
                MouseRegion(
                  onEnter: (_) => onHoverEnter(),
                  onExit: (_) => onHoverExit(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VenomWindowButton(
                        color: const Color(0xFFFFBD2E),
                        icon: Icons.remove,
                        onPressed: () => windowManager.minimize(),
                      ),

                      const SizedBox(width: 8),
                      VenomWindowButton(
                        color: const Color(0xFF28C840),
                        icon: Icons.check_box_outline_blank_rounded,
                        onPressed: () async {
                          if (await windowManager.isMaximized()) {
                            windowManager.unmaximize();
                          } else {
                            windowManager.maximize();
                          }
                        },
                      ),
                      const SizedBox(width: 8),

                      VenomWindowButton(
                        color: const Color(0xFFFF5F57),
                        icon: Icons.close,
                        onPressed: () => windowManager.close(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 3. زر النافذة (نفس الذي صممناه سابقاً مع تحسينات طفيفة)
class VenomWindowButton extends StatefulWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const VenomWindowButton({
    Key? key,
    required this.color,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<VenomWindowButton> createState() => _VenomWindowButtonState();
}

class _VenomWindowButtonState extends State<VenomWindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: 10, // زيادة التوهج قليلاً
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0,
              child: Icon(
                widget.icon,
                size: 10,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _addNewTask(BuildContext context) {
  final pageManager = Provider.of<PageManager>(context, listen: false);
  pageManager.goToAddTask();
}
   