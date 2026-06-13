class Idea {
  String? id; // Identificador único de la idea
  String title; // Título o nombre del proyecto
  String description; // Detalles de la idea (Texto Plano)
  String? imagePath; // Ruta de la imagen adjunta
  String status; // Estado: 'idea', 'in_progress' o 'completed'
  bool isFavorite; // Si está marcada como favorita (estrella)
  bool isArchived; // Si la idea está archivada
  bool remindMe; // Si el usuario quiere recibir un recordatorio
  final DateTime createdAt; // Fecha en la que se creó
  DateTime? targetDate; // Fecha límite opcional
  List<String> tags; // Etiquetas personalizadas (ej: #Trabajo)

  // Constructor: Crea una nueva idea con estos datos
  Idea({
    this.id,
    required this.title,
    required this.description,
    this.imagePath,
    this.status = 'idea', // Por defecto es solo una idea
    this.isFavorite = false, // Por defecto no es favorita
    this.isArchived = false, // Por defecto no está archivada
    this.remindMe = false, // Por defecto no hay recordatorio
    required this.createdAt,
    this.targetDate,
    this.tags = const [], // Por defecto no hay etiquetas
  });

  // Convierte un formato de texto (JSON) en un objeto Idea para usarlo en la app
  factory Idea.fromJson(Map<String, dynamic> json) {
    return Idea(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      status: json['status'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      remindMe: json['remindMe'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetDate: json['targetDate'] != null 
          ? DateTime.parse(json['targetDate'] as String) 
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  // Convierte un objeto Idea en texto (JSON) para guardarlo en el móvil
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'status': status,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'remindMe': remindMe,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'tags': tags,
    };
  }

  // Crea una copia de la idea pero permite cambiar algunos datos (como el favorito)
  Idea copyWith({
    String? id,
    String? title,
    String? description,
    String? imagePath,
    String? status,
    bool? isFavorite,
    bool? isArchived,
    bool? remindMe,
    DateTime? createdAt,
    DateTime? targetDate,
    List<String>? tags,
  }) {
    return Idea(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      remindMe: remindMe ?? this.remindMe,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      tags: tags ?? this.tags,
    );
  }
}
