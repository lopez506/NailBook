# NailBook — Roadmap

Estado (20 nov 2026): **aprobado por Fabián** (fases y orden de diseño). Sin plazos: se avanza fase por fase y cada una termina con algo que se puede ver funcionando.

Reglas del roadmap:
- **Trabajar ordenado:** una fase a la vez, una etapa a la vez dentro de cada fase, con confirmación de Fabián.
- **La seguridad se construye dentro de cada fase**, no al final. La Fase 9 solo verifica y completa (`06-seguridad` manda).
- **📁 Avisos de creación:** el chat de Código marca con "📁 Crea:" y la ruta exacta cada vez que haya que crear un repositorio, carpeta, cuenta o archivo nuevo. Antes de la Fase 0 no hay que crear nada.
- Todas las fases siguen `01-direccion-arte`, `02-arquitectura`, `05-convenciones`, `06-seguridad`, `07-despliegue` y `08-herramientas`.

## Orden de diseño (decidido)
El diseño se divide en dos:
- **Fase 2A, diseño base** (antes de construir pantallas): logo, paleta y tipografía como tokens, componentes base y mockups de Inicio, Servicios y Reservar. Se cierra después de las Fases 0 y 1 y antes de la Fase 3.
- **Fase 2B, diseño justo a tiempo:** panel de administración (funcional y sobrio), galería y efecto del hero, diseñados cuando llegue su fase de código.

Motivo: evita rehacer código por cambios de diseño y evita diseñar pantallas que luego cambian al verlas funcionando.

## Fases

| Fase | Qué se construye | Qué crea Fabián | Chat |
|---|---|---|---|
| **0. Fundamentos** | Herramientas instaladas (`08-herramientas`), repositorio, ramas `main` y `dev` con protección, `.gitignore`, `.editorconfig`, versiones fijadas (`.nvmrc`, `global.json`), Docker Compose con PostgreSQL, tablero de GitHub Projects | 📁 Repositorio `NailBook` y carpetas `web/`, `api/`, `docs/` | Código |
| **1. Esqueleto andante** | Página que llama a la API, que lee una tabla; CI en verde; publicado en staging | 📁 Cuentas de Vercel, Neon y de la plataforma de la API | Código |
| **2A. Diseño base** | Logo, tokens, componentes base, mockups de Inicio, Servicios y Reservar | Nada de código | Diseño |
| **3. Catálogo y estudio** | Servicios, categorías y extras; páginas Inicio, Servicios y Estudio con datos reales; `next-intl` y cliente de API tipado | 📁 Carpetas de componentes y de `messages/` | Código |
| **4. Reservas (núcleo)** | Horarios, bloqueos, calculador de disponibilidad con pruebas, restricción contra doble reserva, retención de 10 min, "Mi cita" para cancelar y reprogramar | Nada nuevo | Código |
| **2B. Diseño del panel** | Pantallas sobrias del panel de administración | Nada de código | Diseño |
| **5. Panel de administración** | Inicio de sesión con 2FA, agenda, citas, servicios, horarios y ajustes, registro `security_event` | Nada nuevo | Código |
| **6. Pagos, archivos y avisos** | Comprobante SINPE, foto de referencia, pago final e ingresos, correo con Resend, enlaces de WhatsApp | 📁 Cuentas de Cloudinary y Resend | Código |
| **2B. Diseño de la galería** | Pantalla de galería y filtros | Nada de código | Diseño |
| **7. Galería** | Administración y página pública con filtros | Nada nuevo | Código |
| **2B. Diseño del hero y movimiento** | Interacción firma, animaciones | Nada de código | Diseño |
| **8. Interacción firma y pulido** | Efecto de cursor del hero, animaciones, rendimiento y accesibilidad | Nada nuevo | Código |
| **9. Seguridad y operación** | Retención automática, Turnstile, límites, CSP completa, OWASP ZAP, "atacar tu propio sitio", copias, monitoreo, runbooks, guía de la manicurista | 📁 Cuentas de Cloudflare R2, Better Stack y Sentry; carpetas de `docs/` | Código |
| **10. Lanzamiento** | Dominio, DNS, lista de la Parte 5 de `07-despliegue` (revisarla aquí), `v1.0.0`, caso de estudio | 📁 El dominio `.com` | Código |
| **11. Probador virtual** | MediaPipe en el navegador, con revisión de seguridad | Nada nuevo | Diseño y Código |
| **12. Inglés** | `en.json`, rutas `/en`, traducción de servicios | Nada nuevo | Código |

## Por qué la Fase 1 publica algo mínimo
Descubrir pronto los problemas de despliegue (compatibilidad del proxy de Cloudflare con Vercel, arranque en frío de la API, límites de planes gratuitos) en lugar de tropezar con ellos en el lanzamiento. En esa fase se verifican de nuevo los precios y límites de `07-despliegue`.

## Qué cierra cada fase
Una fase está terminada cuando: (1) lo construido funciona de punta a punta, (2) la CI está en verde, (3) las pruebas de lo nuevo pasan, (4) lo que toca de seguridad (`06-seguridad`) está aplicado, (5) los documentos del proyecto están actualizados y (6) se creó una etiqueta de versión si fue una entrega (`v0.x.0`).

## Pendiente
- Detallar las etapas internas de cada fase al iniciarla (las propone el chat que la ejecuta).
- Fase 0: lo primero es instalar las herramientas de `08-herramientas`.
- Revisión de la Parte 5 de `07-despliegue` en la Fase 10 (diferida a petición de Fabián).
