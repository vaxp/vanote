import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../../domain/entities/diagram_node.dart';

class PropertiesPanelWidget extends StatefulWidget {
  const PropertiesPanelWidget({Key? key}) : super(key: key);

  @override
  State<PropertiesPanelWidget> createState() => _PropertiesPanelWidgetState();
}

class _PropertiesPanelWidgetState extends State<PropertiesPanelWidget> {
  TextEditingController? _contentController;
  TextEditingController? _widthController;
  TextEditingController? _heightController;

  @override
  void dispose() {
    _contentController?.dispose();
    _widthController?.dispose();
    _heightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagramBloc, DiagramState>(
      builder: (context, state) {
        if (state is! DiagramLoaded) return const SizedBox.shrink();

        final node = state.selectedNode;
        if (node == null) {
          return Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Text('Select a node to edit properties', style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        _contentController ??= TextEditingController(text: node.content);
        _widthController ??= TextEditingController(text: node.width.toInt().toString());
        _heightController ??= TextEditingController(text: node.height.toInt().toString());

        return Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Properties', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => context.read<DiagramBloc>().add(const ShowPropertiesPanelEvent(show: false)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Content', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _contentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  onSubmitted: (value) {
                    context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, content: value));
                  },
                ),

                const SizedBox(height: 12),
                const Text('Width', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _widthController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed > 10) {
                      context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, width: parsed));
                    }
                  },
                  onSubmitted: (value) => context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, width: double.tryParse(value) ?? node.width)),
                ),

                const SizedBox(height: 12),
                const Text('Height', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _heightController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed > 10) {
                      context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, height: parsed));
                    }
                  },
                  onSubmitted: (value) => context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, height: double.tryParse(value) ?? node.height)),
                ),

                const SizedBox(height: 12),
                const Text('Color', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                  ].map((color) => GestureDetector(
                    onTap: () => context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, color: color)),
                    child: Container(width: 36, height: 36, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white24))),
                  )).toList(),
                ),

                const SizedBox(height: 12),
                const Text('Shape', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButton<ShapeType>(
                  value: node.shapeType,
                  items: ShapeType.values.map((s) => DropdownMenuItem(value: s, child: Text(s.toString().split('.').last))).toList(),
                  onChanged: (newShape) {
                    if (newShape != null) context.read<DiagramBloc>().add(UpdateNodeEvent(nodeId: node.id, shapeType: newShape.toString()));
                  },
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}
