# Instrucciones y Contexto para el Agente de Candombe App

Este documento establece las reglas, estándares de código, contexto y flujos de trabajo para el agente de IA que trabaje en el proyecto **Candombe App**.

## 1. Contexto del Proyecto
- **Nombre**: Candombe App
- **Propósito**: Aplicación móvil diseñada para asistir en los ensayos de Candombe (troupe/comparsa).
- **Público Objetivo**: Integrantes de comparsas de candombe, directores de batería y músicos (chico, repique, piano).
- **Idioma Principal**: Toda la documentación, comentarios explicativos clave e interfaz de usuario (UI) deben estar en **español**. El código (nombres de variables, clases, métodos) puede estar en inglés siguiendo las convenciones estándar de desarrollo.

## 2. Stack Tecnológico y Configuración
- **Framework**: Flutter 3.35.6
- **Lenguaje**: Dart 3.9.2
- **Plataformas Soportadas**: Android e iOS (Mobile)
- **Estilo Visual**: Diseño premium, vibrante, moderno, con micro-animaciones, paleta de colores armónica y soporte para modo oscuro/claro (si aplica).

## 3. Directrices de Arquitectura y Código (Dart/Flutter)
- **Estructura del Proyecto**: Orientado a características (Feature-First) o arquitectura limpia (Clean Architecture) para separar adecuadamente la lógica de presentación (UI/Widgets), de negocio (Domain/Use Cases) y datos (Data/Repositories/DataSources).
- **Buenas Prácticas**:
  - Utilizar constructores `const` siempre que sea posible.
  - Definir tipos explícitos para variables y retornos de funciones.
  - Evitar el uso excesivo de widgets con estado (`StatefulWidget`) si se puede delegar a un gestor de estado.
  - Seguir estrictamente las reglas definidas en `analysis_options.yaml`.
  - Manejo de errores estructurado en las llamadas a APIs o almacenamiento local.

## 4. Flujo de Trabajo del Agente
Cuando se reciba una nueva tarea o conjunto de lineamientos:
1. **Fase de Planificación**:
   - Leer detalladamente los requerimientos.
   - Generar un plan de implementación en `implementation_plan.md` si la tarea implica cambios estructurales o nuevas funcionalidades significativas.
   - Esperar la aprobación del usuario antes de proceder a la edición de archivos críticos de código.
2. **Fase de Ejecución**:
   - Crear un archivo `task.md` para hacer seguimiento de las tareas del checklist.
   - Implementar el código paso a paso de forma limpia, modular y documentada.
3. **Fase de Verificación**:
   - Ejecutar pruebas automáticas (`flutter test`) si existen.
   - Crear un `walkthrough.md` para documentar la funcionalidad terminada con explicaciones de lo que se probó.
