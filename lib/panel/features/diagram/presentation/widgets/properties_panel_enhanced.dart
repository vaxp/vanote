import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';

class PropertiesPanelWidget extends StatefulWidget {
  const PropertiesPanelWidget({Key? key}) : super(key: key);

  @override
  State<PropertiesPanelWidget> createState() => _PropertiesPanelWidgetState();
}

class _PropertiesPanelWidgetState extends State<PropertiesPanelWidget> {
  TextEditingController? _contentController;
  TextEditingController? _widthController;
  TextEditingController? _heightController;
  TextEditingController? _fontSizeController;
  TextEditingController? _connectionLabelController;

  @override
  void dispose() {
    _contentController?.dispose();
    _widthController?.dispose();
    _heightController?.dispose();
    _fontSizeController?.dispose();
    _connectionLabelController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagramBloc, DiagramState>(
      builder: (context, state) {
        if (state is! DiagramLoaded || !state.showPropertiesPanel) {
          return const SizedBox.shrink();
        }

        // Show connection properties if connection is selected
        if (state.selectedConnection != null) {
          return _buildConnectionProperties(context, state, state.selectedConnection!);
        }

        // Show node properties if node is selected
        final node = state.selectedNode;
        if (node == null) {
          return Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Text(
                'Select a node or connection to edit properties',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _buildNodeProperties(context, state, node);
      },
    );
  }

  Widget _buildNodeProperties(BuildContext context, DiagramLoaded state, DiagramNode node) {
    _contentController ??= TextEditingController(text: node.content);
    _widthController ??= TextEditingController(text: node.width.toInt().toString());
    _heightController ??= TextEditingController(text: node.height.toInt().toString());
    _fontSizeController ??= TextEditingController(text: node.fontSize.toInt().toString());

    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1A1B26),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Node Properties',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            _buildSectionTitle('Content'),
            const SizedBox(height: 6),
            TextField(
              controller: _contentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Color(0xFF2A2B36),
              ),
              onSubmitted: (value) {
                context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, content: value));
              },
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Text Formatting'),
            const SizedBox(height: 12),
            
            // Font Family
            _buildSectionTitle('Font Family', fontSize: 12),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: node.fontFamily,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2B36),
              style: const TextStyle(color: Colors.white),
              items: ['Roboto', 'Arial', 'Times New Roman', 'Courier New', 'Verdana']
                  .map((font) => DropdownMenuItem(value: font, child: Text(font)))
                  .toList(),
              onChanged: (newFont) {
                if (newFont != null) {
                  context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, fontFamily: newFont));
                }
              },
            ),

            const SizedBox(height: 12),
            // Font Size
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Font Size', fontSize: 12),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fontSizeController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFF2A2B36),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed >= 8 && parsed <= 72) {
                            context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, fontSize: parsed));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Text Color
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Text Color', fontSize: 12),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _showColorPicker(context, node.id, node.textColor, true),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: node.textColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Text Style
            Row(
              children: [
                _buildStyleButton(
                  context,
                  Icons.format_bold,
                  node.isBold,
                  () => context.read<DiagramBloc>().add(
                    UpdateNodeEvent(nodeId: node.id, isBold: !node.isBold),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStyleButton(
                  context,
                  Icons.format_italic,
                  node.isItalic,
                  () => context.read<DiagramBloc>().add(
                    UpdateNodeEvent(nodeId: node.id, isItalic: !node.isItalic),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStyleButton(
                  context,
                  Icons.format_underlined,
                  node.isUnderlined,
                  () => context.read<DiagramBloc>().add(
                    UpdateNodeEvent(nodeId: node.id, isUnderlined: !node.isUnderlined),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Size'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Width', fontSize: 12),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _widthController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFF2A2B36),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed > 10) {
                            context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, width: parsed));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Height', fontSize: 12),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _heightController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFF2A2B36),
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null && parsed > 10) {
                            context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, height: parsed));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Appearance'),
            const SizedBox(height: 12),
            
            // Node Color
            _buildSectionTitle('Node Color', fontSize: 12),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
              ].map((color) => GestureDetector(
                onTap: () => context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, color: color)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: node.color == color ? Colors.cyan : Colors.white24,
                      width: node.color == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Shape'),
            const SizedBox(height: 8),
            DropdownButton<ShapeType>(
              value: node.shapeType,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2B36),
              style: const TextStyle(color: Colors.white),
              items: ShapeType.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.toString().split('.').last),
              )).toList(),
              onChanged: (newShape) {
                if (newShape != null) {
                  context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, shapeType: newShape.toString()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionProperties(BuildContext context, DiagramLoaded state, DiagramConnection conn) {
    _connectionLabelController ??= TextEditingController(text: conn.label);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF1A1B26),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Connection Properties',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Label'),
            const SizedBox(height: 6),
            TextField(
              controller: _connectionLabelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Color(0xFF2A2B36),
              ),
              onSubmitted: (value) {
                context.read<DiagramBloc>().add(UpdateConnectionEvent(connectionId: conn.id, label: value));
              },
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Style'),
            const SizedBox(height: 8),
            DropdownButton<ConnectionStyle>(
              value: conn.style,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2B36),
              style: const TextStyle(color: Colors.white),
              items: ConnectionStyle.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.toString().split('.').last),
              )).toList(),
              onChanged: (newStyle) {
                if (newStyle != null) {
                  context.read<DiagramBloc>().add(
                    UpdateConnectionEvent(connectionId: conn.id, style: newStyle.toString()),
                  );
                }
              },
            ),

            const SizedBox(height: 20),
            _buildSectionTitle('Color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Colors.red,
                Colors.pink,
                Colors.purple,
                Colors.deepPurple,
                Colors.indigo,
                Colors.blue,
                Colors.cyan,
                Colors.teal,
                Colors.green,
                Colors.lightGreen,
                Colors.lime,
                Colors.yellow,
                Colors.amber,
                Colors.orange,
                Colors.deepOrange,
                Colors.brown,
                Colors.grey,
                Colors.blueGrey,
              ].map((color) => GestureDetector(
                onTap: () => context.read<DiagramBloc>().add(
                  UpdateConnectionEvent(connectionId: conn.id, color: color),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: conn.color == color ? Colors.cyan : Colors.white24,
                      width: conn.color == color ? 3 : 1,
                    ),
                  ),
                ),
              )).toList(),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Show Arrow', style: TextStyle(color: Colors.white70)),
                    value: conn.hasArrow,
                    activeColor: Colors.cyan,
                    onChanged: (value) {
                      context.read<DiagramBloc>().add(
                        UpdateConnectionEvent(connectionId: conn.id, hasArrow: value ?? true),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<DiagramBloc>().add(DeleteConnectionEvent(connectionId: conn.id));
                context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false));
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double fontSize = 14}) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white70,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStyleButton(BuildContext context, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? Colors.cyan : const Color(0xFF2A2B36),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? Colors.cyan : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
      ),
    );
  }

  void _showColorPicker(BuildContext context, String nodeId, Color currentColor, bool isTextColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTextColor ? 'Select Text Color' : 'Select Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.white,
              Colors.black,
              Colors.red,
              Colors.pink,
              Colors.purple,
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
              Colors.cyan,
              Colors.teal,
              Colors.green,
              Colors.lightGreen,
              Colors.lime,
              Colors.yellow,
              Colors.amber,
              Colors.orange,
              Colors.deepOrange,
              Colors.brown,
              Colors.grey,
              Colors.blueGrey,
            ].map((color) => GestureDetector(
              onTap: () {
                if (isTextColor) {
                  context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: nodeId, textColor: color));
                } else {
                  context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: nodeId, color: color));
                }
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: currentColor == color ? Colors.cyan : Colors.grey,
                    width: currentColor == color ? 3 : 1,
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

