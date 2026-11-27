# NailBook — Herramientas de trabajo y forma de trabajar (capa 8)

Estado (27 nov 2026): **capa 8 CERRADA, confirmada por Fabián.** Actualizada al cerrar la Fase 0: PostgreSQL 18 y gestor de Node `fnm` decididos.

Las versiones se verificaron en noviembre de 2026; se confirman de nuevo al instalar.

## Decisiones confirmadas por Fabián
1. **Versiones base** fijadas en el repositorio (.NET 10 LTS, Node 24 LTS, Next.js 16, PostgreSQL 18 igual en local y Neon).
2. **Editores:** Visual Studio 2026 (icono morado) para la API y VS Code (icono azul) para el frontend. Ambos trabajan sobre el mismo repositorio. Backend en VS Code también es posible (ver nota abajo).
3. **Herramientas de calidad** de la lista de abajo, con ganchos de Git locales.
4. **Ciclo de trabajo** con tablero en GitHub Projects.

## Versiones base
| Pieza | Versión | Nota |
|---|---|---|
| .NET SDK | 10 (LTS) | Soporte hasta el 10 de noviembre de 2028. .NET 8 y 9 terminan el 10 de noviembre de 2026; .NET 11 sería de soporte corto, no se usa. Se fija en `api/global.json` (SDK 10.0.400 con `rollForward: latestFeature`) |
| Node.js | 24 LTS (26 LTS también válida) | Soporte de 24 hasta abril de 2028. Se fija en `web/.nvmrc` |
| Next.js | 16 | LTS activa |
| PostgreSQL | 18 | La misma versión mayor en Docker Compose y en Neon (Neon la fija al crear el proyecto). En Docker, la imagen 18 monta el volumen en `/var/lib/postgresql` |

## Programas en el PC (Windows)
- **Visual Studio 2026 (Community)** para la API y **VS Code** para el frontend.
- **Docker Desktop** (WSL2) para PostgreSQL y la API en local. Verificar su licencia gratuita para uso personal y educativo. Como todo corre en contenedores, un cambio futuro a Linux no rompe nada.
- **Git para Windows** y **GitHub CLI** (opcional).
- **Gestor de versiones de Node: `fnm`** (decidido en la Fase 0), con Node 24 por defecto.
- **Cliente de base de datos** (DBeaver o pgAdmin).
- **Cliente de API** (Bruno u otro); la documentación OpenAPI sale de la propia API.

## Herramientas de calidad
- **Frontend:** ESLint + Prettier, Vitest + Testing Library, Playwright (punta a punta) con axe (accesibilidad), Lighthouse CI.
- **API:** analizadores de .NET con `.editorconfig`, xUnit y Testcontainers (pruebas contra PostgreSQL real en Docker, clave para probar el doble reservado y el 409).
- **Git local:** Husky + lint-staged + commitlint (Conventional Commits y formato antes de subir). Dónde vive Husky (hoy solo hay Node en `web/`) se decide al llegar a los hooks de pre-commit.
- **Extensiones de VS Code:** ESLint, Prettier, Tailwind CSS IntelliSense, EditorConfig, Docker, Playwright, Error Lens.

## Visual Studio y VS Code: cómo conviven
- No se integran entre sí: comparten el **mismo repositorio de Git**. La carpeta del frontend se abre en VS Code y la solución (`.sln`) de la API en Visual Studio.
- El proyecto **no depende** de Visual Studio: la API se compila, prueba y ejecuta con la CLI `dotnet` y Docker. Cualquier editor sirve.
- **Backend en VS Code es posible** (con la extensión C# Dev Kit). Se eligió Visual Studio porque su depurador y sus herramientas para .NET son más completas (puntos de interrupción condicionales, recarga en caliente, perfiles de CPU y memoria, explorador de pruebas, gestión de paquetes NuGet con interfaz). VS Code tiene la ventaja de ser ligero, multiplataforma y el mismo editor para todo el proyecto. Visual Studio solo existe en Windows, por eso, si Fabián cambia a Linux, el backend pasa a VS Code sin tocar el proyecto. Verificar las condiciones de licencia de C# Dev Kit si se usa.

## Cómo trabajaremos
**Los tres chats**, todos leyendo los documentos del proyecto:
- **Principal:** decisiones, roadmap y documentos.
- **Diseño:** logo, design system, textos, pantallas y movimiento.
- **Código:** guía archivo por archivo, una etapa a la vez, recordando la carpeta. Fabián escribe y ejecuta el código.

Una decisión solo cuenta cuando está escrita en un documento, y cada chat cierra con un resumen corto de traspaso.

**Ciclo de cada funcionalidad** (rebanadas verticales, de la base de datos a la pantalla):
1. Tarea en el tablero de **GitHub Projects**.
2. Rama `feature/...` desde `dev`.
3. El chat de Código da la etapa; Fabián la escribe, la ejecuta y pasa las pruebas.
4. Commit en inglés con Conventional Commits.
5. Pull Request a `dev`, CI en verde, merge.
6. Staging se actualiza solo; `main` se publica cuando toque.

## Si hay una clienta real
- **Licencias:** revisar que las herramientas usadas (Docker Desktop, C# Dev Kit, Visual Studio Community, planes de pago de servicios) permitan uso comercial en la situación de Fabián.
- **Equipo:** si trabaja más de una persona, documentar la instalación del entorno (guía de arranque en `docs/`).

## Pendiente
- Aún se decide al implementar: cliente de API concreto, cliente de base de datos y dónde vive Husky.
