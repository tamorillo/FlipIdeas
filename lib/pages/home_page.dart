import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/idea_provider.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/idea_card.dart';
import '../utils/security_utils.dart';
import '../models/idea.dart';

/// Pantalla Principal donde se listan todas las ideas.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controlador para el texto que escribimos en la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ""; // Texto de búsqueda actual
  String _selectedStatus = "all"; // Filtro de estado actual (todas, favoritas, etc.)

  @override
  void dispose() {
    _searchController.dispose(); // Limpia el controlador al cerrar la pantalla
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calcula el ancho de la pantalla para saber cuántas columnas poner
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Diseño de tarjetas: aumentamos columnas para que no se vean tan grandes
    // >1400px: 4 col, >1000px: 3 col, >600px: 2 col, móvil: 1 col
    final int crossAxisCount = screenWidth > 1400 ? 4 : (screenWidth > 1000 ? 3 : (screenWidth > 600 ? 2 : 1));
    
    // Proporción de la tarjeta: 1.25 es un buen equilibrio para que se vea vertical pero compacta
    final double childAspectRatio = screenWidth > 600 ? 1.25 : 2.2;

    return CustomScaffold(
      showBackButton: false, // No mostrar botón de atrás en la principal
      body: Column(
        children: [
          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                // Al escribir, actualiza la búsqueda y la pantalla
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Busca ideas o #etiquetas...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3949AB)),
                  // Si hay texto, muestra un botón de 'X' para borrarlo
                  suffixIcon: (_searchQuery.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.indigo.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5),
                  ),
                ),
              ),
            ),
          ),

          // --- FILTROS (Botones horizontales) ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip("all", "Todas", Icons.grid_view_rounded, Colors.indigo),
                const SizedBox(width: 8),
                _buildFilterChip("favorites", "Favoritas", Icons.star_rounded, Colors.orange),
                const SizedBox(width: 8),
                _buildFilterChip("idea", "Ideas", Icons.lightbulb_outline, Colors.amber),
                const SizedBox(width: 8),
                _buildFilterChip("in_progress", "En progreso", Icons.rocket_launch_outlined, Colors.blue),
                const SizedBox(width: 8),
                _buildFilterChip("completed", "Completadas", Icons.check_circle_outline, Colors.green),
                const SizedBox(width: 8),
                _buildFilterChip("archived", "Archivadas", Icons.archive_outlined, Colors.grey[700]!),
              ],
            ),
          ),

          // --- LISTADO DE IDEAS (Cuadrícula) ---
          Expanded(
            child: Consumer<IdeaProvider>( // Escucha al almacén de ideas
              builder: (context, provider, child) {
                final List<Idea> allIdeas = provider.ideas;
                final String query = _searchQuery.toLowerCase();
                
                // Filtra la lista según lo que escribimos y el botón seleccionado
                final filteredIdeas = allIdeas.where((idea) {
                  bool matchesSearch;
                  
                  if (query.startsWith('#')) {
                    // BÚSQUEDA POR CATEGORÍA: Si empieza por #, busca SOLO en etiquetas
                    matchesSearch = idea.tags.any((tag) => tag.toLowerCase().contains(query));
                  } else {
                    // BÚSQUEDA GENERAL: Si no, busca en título y descripción
                    matchesSearch = idea.title.toLowerCase().contains(query) || 
                                   idea.description.toLowerCase().contains(query);
                  }
                  
                  bool matchesFilter;
                  if (_selectedStatus == "all") {
                    // Por defecto NO mostrar archivadas en "Todas"
                    matchesFilter = !idea.isArchived;
                  } else if (_selectedStatus == "archived") {
                    // Mostrar SOLO archivadas
                    matchesFilter = idea.isArchived;
                  } else if (_selectedStatus == "favorites") {
                    // Favoritas que NO estén archivadas
                    matchesFilter = idea.isFavorite && !idea.isArchived;
                  } else {
                    // Otros estados (idea, progreso, completada) que NO estén archivadas
                    matchesFilter = idea.status == _selectedStatus && !idea.isArchived;
                  }
                  
                  return matchesSearch && matchesFilter;
                }).toList();

                if (allIdeas.isEmpty) return _buildEmptyState(); // Si no hay nada guardado
                if (filteredIdeas.isEmpty) return _buildNoResultsState(); // Si la búsqueda no dio nada

                // Si es móvil o pantalla estrecha, usamos un listado vertical de tarjetas anchas (horizontales)
                if (screenWidth <= 600) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredIdeas.length,
                    itemBuilder: (context, index) {
                      final idea = filteredIdeas[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(idea.id!),
                          direction: DismissDirection.startToEnd,
                          movementDuration: const Duration(milliseconds: 300),
                          confirmDismiss: (direction) async {
                            final wasArchived = idea.isArchived;
                            // Solo pedimos contraseña si vamos a archivar (no está archivada aún)
                            if (!wasArchived) {
                              return await confirmArchivePassword(context);
                            }
                            return true;
                          },
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: idea.isArchived ? Colors.blue : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              idea.isArchived ? Icons.unarchive : Icons.archive,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          onDismissed: (direction) async {
                            final ideaId = idea.id!;
                            final wasArchived = idea.isArchived;
                            final provider = context.read<IdeaProvider>();
                            final messenger = ScaffoldMessenger.of(context);
                            
                            if (await Vibration.hasVibrator()) {
                              Vibration.vibrate(duration: 40);
                            }

                            if (context.mounted) {
                              provider.toggleArchive(ideaId);
                              
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
                          },
                          child: IdeaCard(idea: idea),
                        ),
                      );
                    },
                  );
                }

                // En pantallas grandes (Tablet/PC) mantenemos la rejilla con el nuevo diseño
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: filteredIdeas.length,
                  itemBuilder: (context, index) => IdeaCard(idea: filteredIdeas[index]),
                );
              },
            ),
          ),
        ],
      ),
      // Botón flotante para añadir una nueva idea
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Vibration.hasVibrator()) {
            Vibration.vibrate(duration: 50);
          }
          if (context.mounted) {
            context.go('/add-idea');
          }
        },
        backgroundColor: const Color(0xFF3949AB),
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // Función para construir cada botoncito de filtro
  Widget _buildFilterChip(String status, String label, IconData icon, Color color) {
    final isSelected = _selectedStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : (isDark ? Colors.white24 : Colors.grey[300]!)),
          boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[600])),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lo que se muestra cuando la app está vacía
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: Colors.indigo[100]),
          const SizedBox(height: 20),
          const Text('¡No hay ideas aún!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          const SizedBox(height: 8),
          const Text('Toca el botón + para empezar', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // Lo que se muestra cuando buscas algo y no existe
  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded, size: 70, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text('No hay nada con estos filtros', style: TextStyle(color: Colors.grey, fontSize: 16)),
          TextButton(
            onPressed: () => setState(() { _selectedStatus = "all"; _searchController.clear(); _searchQuery = ""; }),
            child: const Text('Limpiar filtros'),
          )
        ],
      ),
    );
  }
}
