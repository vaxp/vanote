import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/diagram_bloc.dart';
import '../bloc/diagram_event.dart';
import '../bloc/diagram_state.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/canvas_widget.dart';
import '../widgets/properties_panel_widget.dart';

class DiagramEditorPage extends StatefulWidget {
  final ValueChanged<List<Widget>>? onActionsAvailable;

  const DiagramEditorPage({Key? key, this.onActionsAvailable}) : super(key: key);

  @override
  State<DiagramEditorPage> createState() => _DiagramEditorPageState();
}

class _DiagramEditorPageState extends State<DiagramEditorPage> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<CanvasWidgetState> _canvasKey = GlobalKey<CanvasWidgetState>();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiagramBloc()..add(const LoadDemoDiagramEvent()),
      child: _DiagramEditorContent(
        searchController: _searchController,
        canvasKey: _canvasKey,
        showSearch: _showSearch,
        onSearchToggle: (value) {
          setState(() {
            _showSearch = value;
            if (!value) {
              _searchController.clear();
            }
          });
        },
        onActionsAvailable: widget.onActionsAvailable,
      ),
    );
  }
}

class _DiagramEditorContent extends StatelessWidget {
  final TextEditingController searchController;
  final GlobalKey<CanvasWidgetState> canvasKey;
  final bool showSearch;
  final ValueChanged<bool> onSearchToggle;
  final ValueChanged<List<Widget>>? onActionsAvailable;

  const _DiagramEditorContent({
    required this.searchController,
    required this.canvasKey,
    required this.showSearch,
    required this.onSearchToggle,
    this.onActionsAvailable,
  });

  @override
  Widget build(BuildContext context) {
    // Build app bar actions for the host shell to render
    final actions = <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          onSearchToggle(!showSearch);
        },
      ),
      IconButton(
        icon: const Icon(Icons.undo),
        onPressed: () => context.read<DiagramBloc>().add(const UndoEvent()),
      ),
      IconButton(
        icon: const Icon(Icons.redo),
        onPressed: () => context.read<DiagramBloc>().add(const RedoEvent()),
      ),
      const SizedBox(width: 10),
    ];

    // Notify host about available actions (called every build; lightweight)
    onActionsAvailable?.call(actions);

    return Container(
      color: const Color.fromARGB(0, 0, 0, 0),
      child: Column(
        children: [
          // Search bar
          if (showSearch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color.fromARGB(0, 0, 0, 0),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search nodes...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () {
                      onSearchToggle(false);
                      context.read<DiagramBloc>().add(const SearchNodesEvent(query: ''));
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1B26),
                ),
                onChanged: (value) {
                  context.read<DiagramBloc>().add(SearchNodesEvent(query: value));
                },
              ),
            ),
          // Main content
          Expanded(
            child: Row(
              children: [
                ToolbarWidget(canvasKey: canvasKey),
                Expanded(child: CanvasWidget(key: canvasKey)),
                // Properties panel shown by BLoC state
                BlocBuilder<DiagramBloc, DiagramState>(builder: (context, state) {
                  if (state is DiagramLoaded && state.showPropertiesPanel) {
                    return const PropertiesPanelWidget();
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          // Status bar
          BlocBuilder<DiagramBloc, DiagramState>(
            builder: (context, state) {
              if (state is! DiagramLoaded) return const SizedBox.shrink();

              final selectedCount = state.selectedNodeIds.length + (state.selectedNode != null && !state.selectedNodeIds.contains(state.selectedNode?.id) ? 1 : 0);
              final zoomPercent = (state.zoomLevel * 100).toStringAsFixed(0);

              return Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: const Color(0xFF2A2B36),
                child: Row(
                  children: [
                    Text(
                      'Zoom: ${zoomPercent}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      selectedCount > 0 ? '$selectedCount selected' : 'No selection',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    if (state.searchResults.isNotEmpty)
                      Text(
                        '${state.searchResults.length} found',
                        style: const TextStyle(color: Colors.cyan, fontSize: 12),
                      ),
                    const SizedBox(width: 20),
                    Text(
                      'Nodes: ${state.nodes.length} | Connections: ${state.connections.length}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
