# NailBook — Brief del proyecto

## Qué es
Sitio web para una manicurista (uñas), con reservas reales y panel de administración, construido como pieza de portafolio. El negocio, los servicios y los datos son de ejemplo. Nombre: **NailBook** (provisional, modificable). Idioma: **español**; la versión en inglés llega en una fase posterior.

## Servicios del negocio
Acrílicas, gel, nail art y pedicure. Atención en local.

## Alcance
- Sistema de **reservas con backend**: servicios con duración y precio, calendario con disponibilidad y confirmación.
- Panel de administración para gestionar citas, galería, precios, horarios e ingresos.
- Galería con filtros (estilo, largo, color, ocasión).
- Integraciones locales: WhatsApp (enlace prellenado) y SINPE Móvil (adelanto **opcional**, definido por servicio).
- **Probador virtual de manos** (fase aparte, después de la web y las reservas): detección de la mano en el navegador con MediaPipe y superposición de diseños sobre las puntas de los dedos. Todo se procesa en el dispositivo, sin subir fotos.
- Caso de estudio para el portafolio.

## Stack
- Frontend: Next.js 16 (React + TypeScript), Tailwind, Motion para animación por resortes.
- Backend: ASP.NET Core Web API (.NET 10 LTS) en arquitectura por capas.
- Base de datos: PostgreSQL.
- Imágenes: Cloudinary (propuesto).
- Probador virtual: MediaPipe Hand Landmarker (propuesto).
- Detalle en `02-arquitectura`; hosting y salida a producción en `07-despliegue`; herramientas de trabajo en `08-herramientas`.

## Dirección de arte (resumen)
Editorial claro con un toque oscuro en el hero. Paleta rojo cromado (`#F7F3EF`, `#1A1416`, `#B3122B`), tipografías Fraunces y DM Sans, e interacción firma de cursor que "pule" la pantalla y revela brillo. **Prioridad: ligero y accesible.** Detalle en `01-direccion-arte`.

## Forma de trabajo
- Las reglas de Git, commits, ramas y nombres están en `05-convenciones`.
- La seguridad se construye dentro de cada fase (`06-seguridad`).
- El ciclo de cada funcionalidad y las herramientas están en `08-herramientas`; las fases, en `04-roadmap`.
- Una decisión solo cuenta cuando está escrita en los documentos del proyecto.

## Documentos de este directorio
| Documento | Contenido |
|---|---|
| `00-brief` | Este resumen |
| `01-direccion-arte` | Marca, paleta, tipografía y movimiento |
| `02-arquitectura` | Páginas, flujos, modelo de datos, API, frontend y estructura del código |
| `04-roadmap` | Fases del proyecto |
| `05-convenciones` | Idioma, Git, commits, Pull Requests y nombres |
| `06-seguridad` | Amenazas, controles y privacidad |
| `07-despliegue` | Hosting, CI/CD, entornos, dominio, copias y monitoreo |
| `08-herramientas` | Versiones, programas y forma de trabajar |
