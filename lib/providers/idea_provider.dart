import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/idea.dart';

/// Clase IdeaProvider: Gestiona la lista de ideas, las guarda en almacenamiento persistente
/// y notifica a la interfaz de usuario (UI) cuando hay cambios.
class IdeaProvider with ChangeNotifier {
  /// Lista privada que almacena todas las ideas en memoria.
  final List<Idea> _ideas = [];

  /// Clave constante para identificar las ideas en el almacenamiento del móvil.
  static const String _ideasKey = 'ideas_list';

  /// Constructor: Al iniciar, carga automáticamente las ideas guardadas.
  IdeaProvider() {
    _loadIdeas();
  }

  /// Función para obtener la lista de ideas desde fuera de esta clase.
  List<Idea> get ideas => _ideas;

  /// Obtiene todas las etiquetas únicas de todas las ideas (para los filtros).
  List<String> get allTags {
    final Set<String> tags = {};
    for (var idea in _ideas) {
      tags.addAll(idea.tags);
    }
    final List<String> sortedTags = tags.toList()..sort();
    return sortedTags;
  }

  /// Carga las ideas que están guardadas en el móvil (SharedPreferences).
  Future<void> _loadIdeas() async {
    try {
      final prefs = await SharedPreferences.getInstance(); // Abre el almacenamiento
      final String? ideasJson = prefs.getString(_ideasKey); // Busca el texto guardado
      if (ideasJson != null) {
        // Si hay datos, los convierte de texto a una lista de objetos Idea
        final List<dynamic> decoded = jsonDecode(ideasJson) as List<dynamic>;
        _ideas.clear(); // Limpia la lista actual
        _ideas.addAll(decoded.map((item) => Idea.fromJson(item as Map<String, dynamic>)));
        notifyListeners(); // Avisa a las pantallas para que se actualicen
      }
    } catch (e) {
      debugPrint('Error cargando ideas: $e'); // Muestra error en consola si falla
    }
  }

  /// Guarda la lista actual de ideas en el móvil como un texto (JSON).
  Future<void> _saveIdeas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String ideasJson = jsonEncode(_ideas.map((idea) => idea.toJson()).toList());
      await prefs.setString(_ideasKey, ideasJson);
    } catch (e) {
      debugPrint('Error guardando ideas: $e');
    }
  }

  /// Añade una nueva idea a la lista.
  void addIdea(Idea idea) {
    // Le asigna un ID basado en el tiempo actual para que sea único
    idea.id = DateTime.now().millisecondsSinceEpoch.toString();
    _ideas.insert(0, idea); // La pone al principio de la lista
    _saveIdeas(); // La guarda en el móvil
    notifyListeners(); // Actualiza la pantalla
  }

  /// Actualiza los datos de una idea que ya existe.
  void updateIdea(Idea updatedIdea) {
    final index = _ideas.indexWhere((idea) => idea.id == updatedIdea.id);
    if (index != -1) {
      _ideas[index] = updatedIdea; // Sustituye la idea vieja por la nueva
      _saveIdeas();
      notifyListeners();
    }
  }

  /// Busca una idea específica por su ID.
  Idea? getIdeaById(String id) {
    try {
      return _ideas.firstWhere((idea) => idea.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Borra una idea de la lista.
  void deleteIdea(String id) {
    _ideas.removeWhere((idea) => idea.id == id);
    _saveIdeas();
    notifyListeners();
  }

  /// Cambia el estado de archivado.
  void toggleArchive(String id) {
    final index = _ideas.indexWhere((idea) => idea.id == id);
    if (index != -1) {
      _ideas[index].isArchived = !_ideas[index].isArchived;
      _saveIdeas();
      notifyListeners();
    }
  }

  /// Cambia el estado de favorito (si era favorita deja de serlo y viceversa).
  void toggleFavorite(String id) {
    final index = _ideas.indexWhere((idea) => idea.id == id);
    if (index != -1) {
      _ideas[index].isFavorite = !_ideas[index].isFavorite;
      _saveIdeas();
      notifyListeners();
    }
  }
}
