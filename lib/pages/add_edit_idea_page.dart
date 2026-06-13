import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image/image.dart' as img; // Para redimensionar en Web
import '../models/idea.dart';
import '../providers/idea_provider.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/custom_button.dart';
import '../widgets/privacy_overlay.dart';

/// Pantalla para crear una nueva idea o editar una existente.
class AddEditIdeaPage extends StatefulWidget {
  final String? ideaId;

  const AddEditIdeaPage({super.key, this.ideaId});

  @override
  State<AddEditIdeaPage> createState() => _AddEditIdeaPageState();
}

class _AddEditIdeaPageState extends State<AddEditIdeaPage> {
  final _formKey = GlobalKey<FormState>(); 
  late TextEditingController _titleController; 
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  late String _status; 
  DateTime? _targetDate; 
  String? _imagePath;
  List<String> _tags = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    final provider = context.read<IdeaProvider>();
    final idea = widget.ideaId != null ? provider.getIdeaById(widget.ideaId!) : null;

    _titleController = TextEditingController(text: idea?.title ?? '');
    _descriptionController = TextEditingController(text: idea?.description ?? '');
    _tagController = TextEditingController();

    _status = idea?.status ?? 'idea';
    _targetDate = idea?.targetDate;
    _imagePath = idea?.imagePath;
    _tags = List.from(idea?.tags ?? []);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String text) {
    final rawTags = text.split(' '); // Permite añadir varias separadas por espacio
    for (var tag in rawTags) {
      tag = tag.trim();
      if (tag.isNotEmpty) {
        if (!tag.startsWith('#')) tag = '#$tag';
        if (!_tags.contains(tag)) {
          setState(() {
            _tags.add(tag);
          });
        }
      }
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'es_ES',
          onResult: (val) => setState(() {
            if (val.finalResult) {
              final newText = val.recognizedWords;
              if (newText.isNotEmpty) {
                final currentText = _descriptionController.text;
                _descriptionController.text = "$currentText $newText";
                _descriptionController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _descriptionController.text.length)
                );
              }
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _saveIdea() async {
    // Si el usuario escribió algo en el campo de etiquetas pero no pulsó "Añadir"
    if (_tagController.text.isNotEmpty) {
      _addTag(_tagController.text);
    }

    if (_formKey.currentState!.validate()) {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 100);
      }
      if (mounted) {
        final provider = context.read<IdeaProvider>();
        final idea = Idea(
          id: widget.ideaId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imagePath: _imagePath,
          status: _status,
          createdAt: widget.ideaId == null ? DateTime.now() : provider.getIdeaById(widget.ideaId!)!.createdAt,
          targetDate: _targetDate,
          tags: _tags,
        );
        widget.ideaId == null ? provider.addIdea(idea) : provider.updateIdea(idea);
        context.go('/');
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // Desactivamos temporalmente el filtro de privacidad
      PrivacyOverlay.showOverlay = false;
      
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }

        if (kIsWeb) {
          // --- PROCESO PARA WEB (BASE64 + REDIMENSIÓN) ---
          final bytes = await image.readAsBytes();
          
          // Decodificamos la imagen original
          img.Image? originalImage = img.decodeImage(bytes);
          
          if (originalImage != null) {
            // Redimensionamos a un máximo de 800px para no saturar el localStorage (límite 5MB)
            img.Image resized = img.copyResize(originalImage, width: 800);
            
            // Convertimos a JPG con calidad media para ahorrar espacio
            final compressedBytes = img.encodeJpg(resized, quality: 70);
            final String base64Image = base64Encode(compressedBytes);
            
            setState(() => _imagePath = 'data:image/jpeg;base64,$base64Image');
          }
        } else {
          // En MÓVIL, guardamos el archivo en la carpeta de documentos de la app.
          final directory = await getApplicationDocumentsDirectory();
          final String fileName = 'idea_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
          final String permanentPath = p.join(directory.path, fileName);
          final File localImage = await File(image.path).copy(permanentPath);
          setState(() => _imagePath = localImage.path);
        }
      }
    } catch (e) {
      debugPrint("Error al elegir imagen: $e");
    } finally {
      // ESTO ES VITAL: Pase lo que pase, volvemos a activar la privacidad
      PrivacyOverlay.showOverlay = true;
    }
  }

  void _showFullScreenImage() {
    if (_imagePath == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(child: InteractiveViewer(child: _buildImageWidget(_imagePath!))),
            Positioned(
              top: 40, right: 20,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
            ),
          ],
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
      if (kIsWeb) return const Icon(Icons.broken_image);
      return Image.file(File(path), fit: fit);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E))),
        child: child!,
      ),
    );
    if (picked != null) {
      if (await Vibration.hasVibrator()) { Vibration.vibrate(duration: 50); }
      setState(() => _targetDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      title: widget.ideaId == null ? 'Crear Idea' : 'Editar Idea',
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("NOMBRE DEL PROYECTO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3949AB), letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4), 
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.indigo[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF3949AB).withValues(alpha: 0.2))),
                      child: TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(hintText: 'Ej: Mi nueva App...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                        validator: (value) => value!.isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _selectDate(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.event_note_rounded, color: isDark ? Colors.indigo[200] : const Color(0xFF3949AB), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _targetDate == null ? 'Fecha' : DateFormat('dd/MM').format(_targetDate!),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _targetDate == null ? Colors.grey : (isDark ? Colors.indigo[100] : const Color(0xFF1A237E))),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusIcon('idea', Icons.lightbulb, Colors.amber),
                            const SizedBox(width: 8),
                            _buildStatusIcon('in_progress', Icons.rocket_launch, Colors.blue),
                            const SizedBox(width: 8),
                            _buildStatusIcon('completed', Icons.check_circle, Colors.green),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("DESARROLLA TU IDEA AQUÍ...", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3949AB), letterSpacing: 1.2)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (await Vibration.hasVibrator()) {
                                  Vibration.vibrate(duration: 40);
                                }
                                setState(() => _isPreview = !_isPreview);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isPreview ? Colors.indigo[100] : Colors.indigo[50], 
                                  shape: BoxShape.circle, 
                                  border: Border.all(color: _isPreview ? const Color(0xFF3949AB) : Colors.indigo.withValues(alpha: 0.2))
                                ),
                                child: Icon(_isPreview ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: const Color(0xFF3949AB), size: 20),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _listen,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: _isListening ? Colors.red.withValues(alpha: 0.2) : Colors.indigo[50], shape: BoxShape.circle, border: Border.all(color: _isListening ? Colors.red : Colors.indigo.withValues(alpha: 0.2))),
                                child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isListening ? Colors.red : const Color(0xFF3949AB), size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 250), 
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white, 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2))
                      ),
                      child: _isPreview 
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: MarkdownBody(
                              data: _descriptionController.text.isEmpty ? "*Nada que mostrar*" : _descriptionController.text,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15),
                                h1: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                                listBullet: TextStyle(color: isDark ? Colors.indigo[200] : const Color(0xFF3949AB)),
                              ),
                            ),
                          )
                        : TextFormField(
                            controller: _descriptionController,
                            maxLines: null, // Permite que crezca según escribimos
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: _isListening ? 'Escuchando...' : 'Cuéntanos los detalles...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                    ),
                    const SizedBox(height: 25),
                    const Text("ETIQUETAS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3949AB), letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        backgroundColor: isDark ? Colors.indigo.withValues(alpha: 0.3) : Colors.indigo[50],
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(tag),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                    if (_tags.isNotEmpty) const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4), 
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.indigo[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF3949AB).withValues(alpha: 0.2))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                hintText: 'Añadir etiqueta (ej: Trabajo)...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                              onFieldSubmitted: _addTag,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF3949AB)),
                            onPressed: () => _addTag(_tagController.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text("IMAGEN INSPIRADORA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3949AB), letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    if (_imagePath != null)
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _showFullScreenImage, 
                            child: Container(
                              height: 180, width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20), 
                                image: DecorationImage(
                                  image: _buildImageProvider(_imagePath!), 
                                  fit: BoxFit.cover
                                )
                              ),
                            ),
                          ),
                          Positioned(top: 8, right: 8, child: CircleAvatar(backgroundColor: Colors.black.withValues(alpha: 0.5), child: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white), onPressed: () => setState(() => _imagePath = null)))),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 100, width: double.infinity,
                          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3949AB).withValues(alpha: 0.3))),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: const Color(0xFF3949AB).withValues(alpha: 0.5), size: 30), const SizedBox(height: 8), Text("Añadir una foto", style: TextStyle(color: const Color(0xFF3949AB).withValues(alpha: 0.7), fontWeight: FontWeight.bold))]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SafeArea(child: SizedBox(width: double.infinity, child: CustomButton(text: widget.ideaId == null ? 'CREAR AHORA' : 'GUARDAR', onPressed: _saveIdea))),
          ),
        ],
      ),
    );
  }

  ImageProvider _buildImageProvider(String path) {
    if (path.startsWith('data:image')) {
      final bytes = base64Decode(path.split(',').last);
      return MemoryImage(bytes);
    } else if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      if (kIsWeb) return const AssetImage('assets/images/placeholder.png'); // Fallback para web
      return FileImage(File(path));
    }
  }

  Widget _buildStatusIcon(String value, IconData icon, Color color) {
    final isSelected = _status == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        if (await Vibration.hasVibrator()) {
          Vibration.vibrate(duration: 50);
        }
        setState(() => _status = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          // Si está seleccionado, color sólido. Si no, un toque muy suave del color
          color: isSelected
              ? color
              : (isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08)),
          shape: BoxShape.circle,
          border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.2)),
              width: 2),
          // Añadimos una pequeña sombra si está seleccionado
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Icon(
          icon,
          // El icono ahora siempre tiene color para que se vea bien
          color: isSelected
              ? Colors.white
              : (isDark ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.6)),
          size: 20,
        ),
      ),
    );
  }
}
