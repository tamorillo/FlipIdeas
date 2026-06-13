import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart'; // Para forzar la vibración
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/idea.dart';
import '../providers/idea_provider.dart';
import '../utils/security_utils.dart';

// Widget que representa cada tarjeta individual de una idea en la lista.
class IdeaCard extends StatefulWidget {
  final Idea idea; // La idea que debe mostrar esta tarjeta

  const IdeaCard({super.key, required this.idea});

  @override
  State<IdeaCard> createState() => _IdeaCardState();
}

class _IdeaCardState extends State<IdeaCard> {
  // Función para compartir la idea con otras apps (WhatsApp, Mail, etc.)
  void _shareIdea() {
    final String text = "💡 *¡Mira mi nueva idea en FlipIdeas!* \n\n"
        "📌 *Título:* ${widget.idea.title}\n"
        "📝 *Descripción:* ${widget.idea.description}\n"
        "${widget.idea.targetDate != null ? "📅 *Fecha objetivo:* ${DateFormat('dd/MM/yyyy').format(widget.idea.targetDate!)}\n" : ""}"
        "\nEnviado desde FlipIdeas";
    SharePlus.instance.share(ShareParams(text: text));
  }

  // Define el color de la etiqueta según el estado
  Color _getStatusColor(String status) {
    switch (status) {
      case 'idea': return Colors.amber[700]!;
      case 'in_progress': return Colors.blue[600]!;
      case 'completed': return Colors.green[600]!;
      default: return Colors.grey;
    }
  }

  // Define el texto de la etiqueta según el estado
  String _getStatusLabel(String status) {
    switch (status) {
      case 'idea': return 'IDEA';
      case 'in_progress': return ' EN PROGRESO';
      case 'completed': return 'COMPLETADO';
      default: return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWebLayout = screenWidth > 600;

    return Card(
      elevation: 3, // Elevación suave
      clipBehavior: Clip.antiAlias, // Asegura que la barra de color respete los bordes
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => context.go('/edit-idea/${widget.idea.id}'),
        onLongPress: () async {
          // Vibración al mantener pulsado
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 50);
          }
          if (context.mounted) {
            _confirmDelete(context); // Muestra el diálogo de eliminar
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: isWebLayout 
          ? Column( // --- DISEÑO VERTICAL (WEB) ---
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 8,
                  color: _getStatusColor(widget.idea.status),
                ),
                if (widget.idea.imagePath != null)
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: _buildImageWidget(widget.idea.imagePath!, fit: BoxFit.cover),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCardContent(context, isDark),
                  ),
                ),
              ],
            )
          : IntrinsicHeight( // --- DISEÑO HORIZONTAL (MÓVIL) ---
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    color: _getStatusColor(widget.idea.status),
                  ),
                  if (widget.idea.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 80,
                          child: _buildImageWidget(widget.idea.imagePath!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: _buildCardContent(context, isDark),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.contain}) {
    if (path.startsWith('data:image')) {
      final bytes = base64Decode(path.split(',').last);
      return Image.memory(bytes, fit: fit);
    } else if (path.startsWith('http')) {
      return Image.network(path, fit: fit);
    } else {
      if (kIsWeb) return const Icon(Icons.broken_image, color: Colors.grey);
      return Image.file(File(path), fit: fit);
    }
  }

  // Contenido común de la tarjeta (Títulos, descripción, tags, iconos)
  Widget _buildCardContent(BuildContext context, bool isDark) {
    final bool isWebLayout = MediaQuery.of(context).size.width > 600;

    // Widget con la parte superior (Título, Desc, Tags)
    Widget topContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila superior: Título y Estrella
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.idea.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: widget.idea.status == 'completed'
                      ? (isDark ? Colors.white54 : const Color(0xFF1A237E).withValues(alpha: 0.5))
                      : (isDark ? Colors.white : const Color(0xFF1A237E)),
                  decoration: widget.idea.status == 'completed' 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // --- ESTRELLA DE FAVORITO ---
            GestureDetector(
              onTap: () async {
                if (await Vibration.hasVibrator()) {
                  Vibration.vibrate(duration: 80);
                }
                if (context.mounted) {
                  context.read<IdeaProvider>().toggleFavorite(widget.idea.id!);
                }
              },
              child: Icon(
                widget.idea.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 26,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Descripción con soporte para Markdown
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: isWebLayout ? 120 : 80),
          child: ClipRect(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: MarkdownBody(
                data: widget.idea.description,
                selectable: false,
                softLineBreak: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  listBullet: TextStyle(
                    color: isDark ? Colors.indigo[200] : const Color(0xFF3949AB),
                    fontSize: 13,
                  ),
                  pPadding: EdgeInsets.zero,
                  listIndent: 20,
                  blockSpacing: 4, 
                ),
              ),
            ),
          ),
        ),
        if (widget.idea.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.idea.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? Colors.indigo.withValues(alpha: 0.2) : Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.indigo[400]!.withValues(alpha: 0.3) : Colors.indigo[100]!),
              ),
              child: Text(
                tag.startsWith('#') ? tag : '#$tag',
                style: TextStyle(
                  fontSize: 10, 
                  color: isDark ? Colors.indigo[200] : const Color(0xFF1A237E), 
                  fontWeight: FontWeight.bold
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En Web (Grid) usamos Expanded + Scroll para evitar desbordar la tarjeta fija.
        // En Móvil dejamos que el contenido dicte el tamaño de la tarjeta.
        if (isWebLayout)
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: topContent,
            ),
          )
        else
          topContent,

        const SizedBox(height: 12),
        // Fila inferior: Fecha, Estado y Menú
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.idea.targetDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.indigo.withValues(alpha: 0.2) 
                      : const Color(0xFF3949AB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event, 
                      size: 14, 
                      color: isDark ? Colors.indigo[200] : const Color(0xFF3949AB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM').format(widget.idea.targetDate!),
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.indigo[100] : const Color(0xFF3949AB),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Text('Sin fecha', style: TextStyle(fontSize: 11, color: Colors.grey)),
            
            const SizedBox(width: 12),
            _buildStatusPicker(context),
            
            const Spacer(),

            const SizedBox(width: 8),

            // --- MENÚ DE TRES PUNTOS ---
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 22, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 150),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.go('/edit-idea/${widget.idea.id}');
                    break;
                  case 'archive':
                    final ideaId = widget.idea.id!;
                    final wasArchived = widget.idea.isArchived;
                    final provider = context.read<IdeaProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    if (!wasArchived) {
                      confirmArchivePassword(context).then((confirmed) {
                        if (confirmed) {
                          provider.toggleArchive(ideaId);
                          _showArchiveSnackBar(messenger, wasArchived, ideaId, provider, isDark);
                        }
                      });
                    } else {
                      provider.toggleArchive(ideaId);
                      _showArchiveSnackBar(messenger, wasArchived, ideaId, provider, isDark);
                    }
                    break;
                  case 'delete':
                    _confirmDelete(context);
                    break;
                  case 'share':
                    _shareIdea();
                    break;
                }
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit_outlined, color: Colors.indigo, size: 20), SizedBox(width: 10), Text('Editar')]),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(children: [
                    Icon(widget.idea.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, color: Colors.orange[700], size: 20), 
                    const SizedBox(width: 10), 
                    Text(widget.idea.isArchived ? 'Desarchivar' : 'Archivar')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(children: [Icon(Icons.share_rounded, color: Colors.teal, size: 20), SizedBox(width: 10), Text('Compartir')]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), SizedBox(width: 10), Text('Eliminar')]),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showArchiveSnackBar(ScaffoldMessengerState messenger, bool wasArchived, String ideaId, IdeaProvider provider, bool isDark) {
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasArchived ? 'Idea desarchivada' : 'Idea archivada',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF5C6BC0) : const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: Colors.amberAccent,
          onPressed: () {
            provider.toggleArchive(ideaId);
            messenger.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Widget para elegir el estado (Idea, Progreso, Hecho)
  Widget _buildStatusPicker(BuildContext context) {
    final statusColor = _getStatusColor(widget.idea.status);
    
    return PopupMenuButton<String>(
      onSelected: (String newStatus) async {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }
        if (context.mounted) {
          final provider = context.read<IdeaProvider>();
          provider.updateIdea(widget.idea.copyWith(status: newStatus));
        }
      },
      tooltip: 'Cambiar estado',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              _getStatusLabel(widget.idea.status),
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        _buildStatusMenuItem('idea', 'Idea', Icons.lightbulb, Colors.amber),
        _buildStatusMenuItem('in_progress', 'En progreso', Icons.rocket_launch, Colors.blue),
        _buildStatusMenuItem('completed', 'Completada', Icons.check_circle, Colors.green),
      ],
    );
  }

  // Ítem individual del menú de estados
  PopupMenuItem<String> _buildStatusMenuItem(String value, String text, IconData icon, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Diálogo para confirmar si realmente se quiere borrar la idea
  void _confirmDelete(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar idea'),
        content: Text('¿Deseas eliminar "${widget.idea.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: TextStyle(color: isDark ? Colors.indigo[200] : Colors.indigo)),
          ),
          TextButton(
            onPressed: () {
              context.read<IdeaProvider>().deleteIdea(widget.idea.id!);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
