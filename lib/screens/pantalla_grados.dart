// lib/screens/pantalla_grados.dart

import 'package:flutter/material.dart';
import '../data/datos_curriculo.dart';
import '../models/estructura_academica.dart';
import '../models/perfil_estudiante.dart';

/// Pantalla que presenta el listado de Grados Académicos de Secundaria en Nicaragua (7mo a 11mo Año).
class PantallaGrados extends StatelessWidget {
  final PerfilEstudiante perfil;
  final Function(Grado) onSeleccionarGrado;
  final VoidCallback onEditarPerfil;

  const PantallaGrados({
    super.key,
    required this.perfil,
    required this.onSeleccionarGrado,
    required this.onEditarPerfil,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.school, color: tema.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SecundariaIA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'Currículo MINED - Nicaragua',
                  style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Perfil',
            onPressed: onEditarPerfil,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Tarjeta Resumen del Estudiante
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onEditarPerfil,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tema.colorScheme.primary, tema.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Hola, ${perfil.nombre.isNotEmpty ? perfil.nombre : "Estudiante"}!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Tutor activo para Secundaria de Nicaragua',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.edit, color: Colors.white70, size: 18),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.psychology, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Estilo: ${perfil.estiloAprendizaje.nombreLegible}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Selecciona un Grado Académico',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Lista de Grados
              ...DatosCurriculo.grados.map((Grado grado) {
                final bool esGradoActual = grado.id == perfil.gradoId;
                final Color colorGrado = Color(grado.colorHex);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSeleccionarGrado(grado),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colorGrado.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.school, color: colorGrado, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      grado.nombre,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    if (esGradoActual) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: tema.colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Tu Grado',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: tema.colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  grado.alias,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorGrado,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  grado.descripcion,
                                  style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.menu_book, size: 14, color: tema.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${grado.unidades.length} unidades curriculares',
                                      style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16, color: tema.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}