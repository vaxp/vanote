import '../../domain/entities/diagram_node.dart';
import '../../domain/entities/diagram_connection.dart';

class DiagramHistoryState {
  final List<DiagramNode> nodes;
  final List<DiagramConnection> connections;

  DiagramHistoryState({
    required this.nodes,
    required this.connections,
  });
}

