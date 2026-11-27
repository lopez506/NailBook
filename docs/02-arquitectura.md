# NailBook — Arquitectura

Estado (20 nov 2026): **capas 1 a 6 cerradas; capa 7 (despliegue) en curso**, ver `07-despliegue`. La seguridad está en `06-seguridad`.

## Plan de análisis (una capa a la vez)
1. Páginas y flujos — **cerrada**
2. Modelo de datos (tablas, relaciones y reglas) — **cerrada**
3. API (endpoints del backend) — **cerrada**
4. Frontend (renderizado, rendimiento, estructura, librerías, inglés) — **cerrada**
5. Estructura del código, principios (SOLID) y control de versiones — **cerrada** (Git y convenciones en `05-convenciones`)
6. Seguridad y privacidad — **cerrada**, ver `06-seguridad`
7. Despliegue (incluye CI/CD) — **en curso**, ver `07-despliegue`

## 1. Mapa del sitio

**Público**
- Inicio: hero con interacción firma, servicios destacados, galería breve, llamada a reservar.
- Servicios: lista con precio y duración por categoría (acrílicas, gel, nail art, pedicure).
- Galería: filtros por estilo, largo, color y ocasión.
- Reservar: flujo principal.
- Mi cita: consultar, reprogramar o cancelar con enlace único, sin cuenta.
- Estudio: ubicación, horario, contacto, preguntas frecuentes (adelanto y cancelación).
- Privacidad: aviso de privacidad en lenguaje claro (`/privacidad`).
- Probador virtual: fase 2.

**Panel de administración (privado)**
Agenda (diaria y semanal), citas, servicios y precios, galería, horarios y bloqueos (vacaciones, días libres), clientas, ajustes, resumen de ingresos.

## Flujo de reserva
1. Elegir servicio(s) y extras
2. Elegir fecha y hora (según duración total)
3. Datos de contacto (nombre y WhatsApp obligatorios; correo opcional; notas; foto de referencia opcional) y **casilla de aceptación del aviso de privacidad** (sin premarcar)
4. **Adelanto por SINPE Móvil (solo si el servicio lo pide)**: sube comprobante (imagen)
5. Confirmación con enlace a "Mi cita" y mensaje de WhatsApp

Sin adelanto, el paso 4 se salta y la cita se confirma sola (según `auto_confirm`).

## Decisiones tomadas
1. **Una manicurista**, con el modelo de datos preparado para varias.
2. **Sin cuentas de clienta**: reservan como invitadas y gestionan la cita con un enlace único.
3. **Adelanto SINPE opcional** (la manicurista decide por servicio si lo pide). Si lo hay, la clienta sube el comprobante y ella lo confirma en el panel (no hay API de SINPE para personas). *Reemplaza la decisión inicial de adelanto obligatorio, porque normalmente se paga al terminar el trabajo.*
4. **Notificaciones**: enlace de WhatsApp prellenado (`wa.me`) más correo. No se usa la API oficial de WhatsApp Business. La manicurista recibe el detalle completo en el panel y un correo de aviso con lo mínimo y un enlace al panel (sin adjuntar comprobantes).
5. **Servicios con extras** (retiro de esmalte, diseño por uña) que cambian duración y precio.
6. **Graphify** (convierte código en grafo de conocimiento para agentes): no se usa ahora, porque el código lo escribe Fabián y no se trabaja con agentes sobre el repo. Candidato opcional más adelante para visualizar la estructura del proyecto o ilustrar el caso de estudio.
7. **Horarios y parámetros son datos, no código**: la manicurista los cambia desde el panel (Horarios y bloqueos, Ajustes). Los cambios aplican a reservas futuras.
8. **Pago final registrado en el panel** al terminar la cita, con resumen de ingresos.
9. **Confirmación automática** cuando no hay adelanto.
10. **Contador de plantones opcional y apagado por defecto**: ajuste `no_show_deposit_threshold` (0 = desactivado). Si la manicurista lo activa, tras ese número de plantones la clienta debe pagar adelanto en la siguiente reserva.
11. **Código en inglés** (variables, funciones, componentes, carpetas, tablas, endpoints, commits). Los textos visibles van en `messages/es.json` y las URLs traducidas son solo un mapeo (carpeta interna `services`, URL `/servicios`).
12. **Arquitectura por capas y SOLID aplicado con equilibrio**, sin patrones pesados innecesarios (sin CQRS/MediatR por moda).
13. **Control de versiones con Git y GitHub**: ramas `main` (producción) y `dev` (integración), más ramas cortas `feature/` y `fix/` borradas al integrarse. Detalle y reglas en `05-convenciones`.
14. **Seguridad de reservas (parte 3 de `06-seguridad`)**: token de cita de 256 bits con hash, "Mi cita" con datos mínimos, límites anti-abuso. Detalle en `06-seguridad`.
15. **Privacidad (parte 5 de `06-seguridad`)**: retención automática de datos, anonimizar en lugar de borrar, aviso de privacidad con consentimiento explícito, sin rastreadores de terceros, cifrado en reposo del proveedor más cifrado de aplicación para secretos.
16. **Origen único (parte 6 de `06-seguridad`)**: frontend y API bajo el mismo dominio; las rutas `/api/*` pasan por un proxy (por ejemplo `rewrites` de Next.js o un proxy inverso) hacia ASP.NET. La cookie `__Host-` funciona y CORS queda cerrado. **Cloudflare delante** (plan gratuito) como objetivo de protección en el borde; el detalle de cómo se aplica depende del hosting y se define en la capa 7. La seguridad no depende de planes de pago: casi todo son configuraciones.
17. **Capa de seguridad cerrada (20 nov 2026)** tras cruzarla con el OWASP Top 10:2025; los 8 refuerzos están integrados en `06-seguridad`. Se revisa de nuevo con el "ataque a tu propio sitio" antes del lanzamiento y al agregar el probador virtual.

## 2. Modelo de datos

Base: PostgreSQL. Precios en colones enteros. Fechas en UTC (Costa Rica no tiene cambio de hora).

| Grupo | Tabla | Qué guarda |
|---|---|---|
| Catálogo | `service_category` | Acrílicas, gel, nail art, pedicure |
| | `service` | Nombre, descripción, precio base, duración base, activo, `requires_deposit` y porcentaje de adelanto |
| | `service_extra` | Retiro de esmalte, diseño por uña: precio y minutos extra |
| | `service_extra_link` | Qué extras aplican a qué servicio (muchos a muchos) |
| Personas | `staff` | La manicurista (una fila hoy, preparada para varias) |
| | `customer` | Nombre y WhatsApp (obligatorios), correo (opcional); sin cuenta ni contraseña; contador de `no_show`; marca de anonimizada y fecha de aceptación del aviso de privacidad |
| | `admin_user` | Acceso al panel (ASP.NET Identity) |
| Reservas | `booking` | Clienta, profesional, inicio y fin (el fin incluye el margen), estado, totales, monto de adelanto (0 si no aplica), nota, foto de referencia, vencimiento de retención y hash del token del enlace "Mi cita" con su fecha de vigencia |
| | `booking_item` | Cada servicio de la cita, con precio y duración copiados al reservar |
| | `booking_item_extra` | Extras elegidos, también con precio y duración copiados |
| | `payment` | Monto, `kind` (adelanto o pago final), `method` (efectivo, SINPE o tarjeta), comprobante, estado (pendiente, confirmado, rechazado), fecha |
| Disponibilidad | `working_hours` | Horario semanal recurrente; el almuerzo es el hueco entre dos tramos |
| | `time_off` | Vacaciones y bloqueos puntuales |
| Contenido | `gallery_item` | Foto, título, publicada, orden |
| | `gallery_tag` + `gallery_item_tag` | Etiquetas por estilo, largo, color y ocasión para los filtros |
| Ajustes | `setting` | Ver parámetros abajo |
| Seguridad | `security_event` | Tabla **solo de inserción** (el usuario de la API no puede modificar ni borrar): id, fecha UTC, tipo, quién, IP, navegador, objeto afectado (tipo e id), resultado y detalle breve sin secretos. Registra inicios de sesión, bloqueos, cambios de credenciales, pagos confirmados o rechazados, cambios de ajustes, solicitudes de derechos y accesos denegados; se conserva 12 meses (detalle en `06-seguridad`, parte 7) |

Estados de una cita: `hold`, `pending_payment`, `confirmed`, `completed`, `cancelled`, `no_show`, `expired`.

Relaciones clave:
- Una clienta tiene muchas citas; una cita tiene muchos servicios y extras.
- Una cita tiene uno o más pagos.
- Una profesional tiene muchos horarios y bloqueos.
- Una foto de galería tiene muchas etiquetas.

Precio y duración se copian en la cita para que cambios futuros no alteren citas ya hechas.

Pendiente futuro: traducciones de nombres y descripciones de servicios para la versión en inglés (columnas o tabla de traducción).

### Parámetros en `setting` (valores iniciales)
- `slot_step_minutes` = 30 (intervalo entre horas ofrecidas)
- `buffer_minutes` = 10 (margen entre citas, incluido en `ends_at`)
- `min_notice_hours` = 12
- `max_advance_days` = 60
- `hold_minutes` = 10
- `cancel_window_hours` = 24
- `deposit_percent` = 0 por defecto (sin adelanto; cada servicio puede definir el suyo)
- `auto_confirm` = verdadero
- `no_show_deposit_threshold` = 0 (desactivado)
- `max_active_holds_per_customer` = 2 (por WhatsApp y por IP)
- `max_active_bookings_per_customer` = 3 (citas futuras por WhatsApp)
- `booking_link_valid_days_after` = 7 (el enlace "Mi cita" vale hasta 7 días después de la cita)
- `retention_payment_proof_days` = 90 (borrar la imagen del comprobante tras la cita)
- `retention_reference_photo_days` = 30
- `retention_expired_booking_days` = 30
- `retention_inactive_customer_months` = 24 (luego se anonimiza la clienta)
- `retention_security_event_months` = 12
- `public_booking_enabled` = verdadero (interruptor de emergencia: apagado, la web pública muestra "reservas en pausa, escríbenos por WhatsApp" sin tumbar el sitio ni el panel)
- Alerta en el panel si `pending_payment` lleva más de 24 horas sin revisar

### Reglas

**Regla 1: disponibilidad.** El backend es la única fuente de verdad; el frontend solo muestra lo que devuelve y el backend revalida al confirmar. Pasos: (1) tomar el horario del día en `working_hours`, (2) restar `time_off`, (3) restar citas que ocupan tiempo (`hold` vigentes, `pending_payment`, `confirmed`), (4) generar horas cada `slot_step_minutes` y conservar solo las que caben completas (duración total + margen) en un hueco libre, (5) descartar lo que incumple aviso mínimo o anticipación máxima.
Ejemplo: martes 9:00 a 17:00 con almuerzo 12:00 a 13:00 y una cita de 10:00 a 12:00; servicio de 120 min en total (gel 90 + retiro 20 + margen 10) → horas ofrecidas 13:00, 13:30, 14:00, 14:30 y 15:00.

**Regla 2: evitar reserva doble.** La base de datos lo impide con una restricción de exclusión sobre rangos de tiempo (extensión `btree_gist`):
`EXCLUDE USING gist (staff_id WITH =, tstzrange(starts_at, ends_at) WITH &&) WHERE (status IN ('hold','pending_payment','confirmed'))`.
Si dos personas eligen la misma hora a la vez, gana la primera en guardar; la otra recibe HTTP 409 "horario ya no disponible" y la web refresca las horas. Incluye `staff_id`, así que sirve con varias profesionales. Se escribe con SQL en la migración de EF Core.

**Regla 3: retención.** Al elegir la hora la cita nace en `hold` con vencimiento a `hold_minutes`. Con adelanto: al subir el comprobante pasa a `pending_payment` y, al confirmarlo la manicurista, a `confirmed`. Sin adelanto: pasa de `hold` a `confirmed` al completar los datos (si `auto_confirm`). Si vence sin completarse, pasa a `expired` y libera la hora; la web muestra un contador. Un proceso automático limpia las retenciones vencidas cada minuto, y al guardar una cita nueva se vencen en la misma transacción las caducadas que se solapen (la restricción no puede usar la hora actual). `pending_payment` no vence solo.

**Regla 4: cancelación y reprogramación.** Desde "Mi cita" con el enlace único (token aleatorio de 256 bits, solo se guarda el hash). Hasta `cancel_window_hours` antes, la clienta cancela o reprograma sola; dentro de la ventana se le ofrece un botón de WhatsApp. Reprogramar usa el mismo cálculo de disponibilidad ignorando su propia cita y mantiene el pago. Si hubo adelanto (política propuesta, la define la dueña): con 24 horas o más de aviso se reprograma o se devuelve manualmente; con menos, se pierde. La manicurista puede cancelar o reprogramar cuando quiera, con mensaje de WhatsApp prellenado, y marca `no_show` si la clienta no llega. Si la clienta pierde el enlace, la manicurista lo regenera desde el panel y el anterior queda invalidado.

**Regla 5: retención de datos.** Un proceso diario aplica los plazos de `retention_*`: borra imágenes de comprobantes y fotos de referencia vencidas (conserva el registro del pago), purga citas expiradas o canceladas, anonimiza clientas inactivas y borra registros de seguridad antiguos. Anonimizar reemplaza nombre, WhatsApp, correo y notas, y conserva fechas y montos para los ingresos.

### Pago final
Al terminar el trabajo, la manicurista marca la cita `completed` y registra el pago final (efectivo, SINPE o tarjeta). Con esos pagos el panel muestra un resumen de ingresos.

## 3. API

Convenciones: prefijo `/api`, JSON, precios en colones enteros, fechas ISO 8601 con zona horaria (`-06:00`), errores en formato `ProblemDetails`. Códigos clave: 409 si la hora ya fue tomada, 410 si la retención venció. IDs públicos como GUID. Lo que modifica datos pasa por límites de frecuencia (detalle en `06-seguridad`).

### Públicos

| Método y ruta | Qué hace |
|---|---|
| `GET /api/services` | Categorías con servicios (precio, duración, si pide adelanto) y extras |
| `GET /api/gallery?style=&length=&color=&occasion=&page=` | Galería filtrada y paginada |
| `GET /api/gallery/tags` | Etiquetas para los filtros |
| `GET /api/studio` | Ubicación, horario, contacto, preguntas frecuentes |
| `GET /api/availability/days?month=2026-11&serviceIds=..&extraIds=..` | Días del mes con horas libres |
| `GET /api/availability/slots?date=2026-11-24&serviceIds=..&extraIds=..` | Horas libres del día (`{date, totalMinutes, slots[]}`) |
| `POST /api/bookings/holds` | Paso 2: crea la retención; devuelve `bookingId`, token y `holdExpiresAt`; 409 si la hora ya no está libre |
| `POST /api/bookings/{id}/confirm` | Paso 3: contacto, notas y aceptación del aviso de privacidad; sin adelanto queda `confirmed` |
| `POST /api/bookings/{id}/reference-photo` | Foto de referencia opcional (imagen, máx. 5 MB) |
| `POST /api/bookings/{id}/payment-proof` | Paso 4: comprobante SINPE (imagen, máx. 5 MB); pasa a `pending_payment` |
| `GET /api/my-booking/{token}` | Ver la cita (solo datos mínimos) |
| `GET /api/my-booking/{token}/slots?date=` | Horas libres para reprogramar (ignora su propia cita) |
| `POST /api/my-booking/{token}/reschedule` · `cancel` | Reprogramar o cancelar (respeta la ventana de 24 horas) |

El token devuelto en el primer paso se usa en los pasos siguientes; saber el ID no basta para tocar la cita de otra persona. Los endpoints públicos nunca aceptan IDs de clienta o profesional, precios, duraciones, estados ni montos.

### Panel de administración (`/api/admin`, requiere sesión)

| Grupo | Endpoints |
|---|---|
| Acceso | `POST auth/login`, `auth/logout`, `GET auth/me`, `POST auth/change-password` |
| Citas | `GET bookings?from=&to=&status=&q=`, `GET bookings/{id}`, `POST bookings` (cita manual), `POST bookings/{id}/reschedule`, `cancel`, `no-show`, `complete` (registra pago final), `POST bookings/{id}/regenerate-link`, `GET bookings/{id}/whatsapp-link?type=reminder\|cancel\|reschedule` |
| Pagos e ingresos | `GET payments?status=pending`, `POST payments/{id}/confirm`, `reject`, `GET reports/income?from=&to=&groupBy=`, `GET dashboard` |
| Catálogo | CRUD de `categories`, `services`, `extras`; `PUT services/{id}/extras` |
| Disponibilidad y ajustes | `GET/PUT working-hours`, `GET/POST/DELETE time-off`, `GET/PUT settings`, `GET/PUT studio` |
| Galería y clientas | `GET uploads/signature` (subida directa a Cloudinary), CRUD `gallery` y `gallery/tags`, `PUT gallery/reorder`, `GET customers?q=`, `GET customers/{id}`, `PUT customers/{id}` (corregir datos), `POST customers/{id}/anonymize` (derecho de supresión) |

Reglas de la API de administración:
- Servicios y extras con citas históricas se **desactivan, no se borran**.
- Si un cambio de horario o un bloqueo choca con citas existentes, la API devuelve la lista de citas afectadas y pide confirmación; nunca las cancela sola.
- Los **comprobantes de pago son privados**: solo se ven desde el panel con sesión, mediante URLs firmadas de corta duración, nunca con URL pública.

## 4. Frontend (Next.js)

### Renderizado por página

| Página | Estrategia |
|---|---|
| Inicio, Servicios, Estudio, Privacidad | Estática con revalidación (carga instantánea y buen SEO) |
| Galería | Primera página generada y filtros en el navegador con la URL actualizada |
| Reservar | Interactiva en el cliente (flujo con estado, sin SEO) |
| Mi cita | Dinámica, `noindex`, `Referrer-Policy: no-referrer` |
| Panel de administración | Grupo de rutas aparte con autenticación, su código no se mezcla con el público |
| Probador virtual | Carga diferida: MediaPipe solo se descarga en esa página; aviso de privacidad antes de pedir la cámara |

### Rendimiento
- El hero con efectos se carga después del primer pintado: primero una imagen estática (la que mide el rendimiento) y encima se activa la interacción firma.
- Niveles por dispositivo: en celular, menos partículas o sin revelado con cursor; se respeta `prefers-reduced-motion`.
- Imágenes con `next/image` y Cloudinary (AVIF o WebP, tamaños adaptados). Tipografías autoalojadas con `next/font` (Fraunces y DM Sans).
- **Metas (criterio de aceptación):** LCP menor a 2,5 s, CLS menor a 0,1, INP menor a 200 ms, Lighthouse de 90 o más en páginas públicas, medido en un celular de gama media.

### Estructura
Un solo repositorio con dos aplicaciones:
```
NailBook/
├── web/     Next.js (frontend)
├── api/     ASP.NET Core (backend)
└── docs/    copia de los documentos del proyecto
```
Dentro de `web/src/` (nombres en inglés):
```
app/
  (public)/     home, services, gallery, studio, privacy
  (booking)/    booking, my-booking/[token]
  admin/        login, agenda, bookings, services, working-hours...
  try-on/       fase 2
components/     ui/ · sections/ · booking/ · admin/
lib/            api/ (cliente tipado) · motion/ · webgl/ · i18n/
styles/         tokens (variables de color y tipografía)
messages/       es.json · en.json
```

### Librerías
- Estilos: Tailwind con tokens como variables CSS.
- Datos del servidor en el navegador: TanStack Query.
- Formularios y validación: React Hook Form + Zod.
- Animación: Motion (animación por resortes).
- Componentes accesibles: Radix UI, estilizados por nosotros.
- Fechas: date-fns (todo se muestra en hora de Costa Rica).
- Efecto del hero: canvas/WebGL propio y ligero, cargado después; se evita Three.js por su peso (se define en el chat de Diseño).

### Tipos compartidos con el backend
ASP.NET Core genera un archivo OpenAPI; con `openapi-typescript` se generan los tipos de TypeScript y un cliente tipado (`npm run gen:api`). Si el backend cambia un campo y el frontend lo usa mal, el editor lo marca como error.

### Inglés
`next-intl` desde el inicio, todos los textos en `messages/es.json` (ninguno escrito a mano en componentes), rutas listas para `/es` y `/en` con direcciones traducidas.

### Extras
SEO (metadatos por página, `sitemap`, datos estructurados JSON-LD de negocio local) y accesibilidad (pruebas automáticas con axe).

## 5. Estructura del código, principios y control de versiones

### Backend: arquitectura por capas

| Proyecto | Responsabilidad |
|---|---|
| `NailBook.Api` | Endpoints delgados: reciben la petición y devuelven la respuesta |
| `NailBook.Application` | Casos de uso: `CreateHold`, `ConfirmBooking`, `GetAvailability`... |
| `NailBook.Domain` | Entidades y reglas: estados de la cita, rangos de tiempo, dinero |
| `NailBook.Infrastructure` | EF Core, Cloudinary, correo y almacenamiento |

Las dependencias apuntan hacia adentro: el dominio no sabe nada de la base de datos.

### SOLID con ejemplos del proyecto
- **S:** `AvailabilityCalculator` solo calcula horas libres; otra clase maneja las transiciones de estado de la cita.
- **O:** notificaciones por una interfaz `INotificationSender`; se agrega correo o la API de WhatsApp sin tocar lo existente.
- **L:** cualquier implementación de almacenamiento de archivos puede reemplazar a otra (por ejemplo una falsa en pruebas).
- **I:** interfaces pequeñas (`IClock`, `IFileStorage`) en vez de una gigante.
- **D:** los casos de uso dependen de interfaces y el contenedor de inyección de dependencias las conecta.

### Otras buenas prácticas
- Pruebas unitarias del cálculo de disponibilidad (función pura) y pruebas con PostgreSQL real para la restricción contra doble reserva.
- Reloj abstracto (`IClock`) para probar vencimientos y ventanas de tiempo.
- DTOs separados de las entidades, validación centralizada, registros sin datos sensibles.
- Escalable: API sin estado (replicable), profesional ya modelada para varias, proceso de limpieza de retenciones separable más adelante.
- Frontend: estructura por funcionalidad, componentes pequeños, lógica en hooks separados de la interfaz, **cero reglas de negocio en el frontend**, TypeScript estricto, ESLint y Prettier.
- Equilibrio: SOLID donde aporta, sin sobrecargar el proyecto.

### Control de versiones
Aprobado. Ramas `main` (producción) y `dev` (integración), ramas cortas `feature/` y `fix/` borradas al integrarse, commits en inglés con formato Conventional Commits, Pull Requests, versiones etiquetadas, revisiones automáticas con GitHub Actions y secretos nunca en Git. **Reglas completas en `05-convenciones`.**

## 6. Seguridad y privacidad
**Cerrada.** Documento propio: **`06-seguridad`** (8 partes, cruzada con el OWASP Top 10:2025).

## 7. Despliegue
**En curso.** Documento propio: **`07-despliegue`**.

## Pendiente
- Capa 7 (despliegue): hosting, CI/CD, staging, dominio, copias y monitoreo con herramientas concretas.
- Diagrama de tablas en la Whiteboard.
