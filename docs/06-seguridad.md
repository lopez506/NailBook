# NailBook — Seguridad y privacidad

Estado (20 nov 2026): **capa 6 CERRADA. Partes 1 a 8 cerradas** (los 8 refuerzos del cruce con OWASP ya están integrados en sus partes). Se vuelve a revisar con el "ataque a tu propio sitio" antes del lanzamiento y al agregar el probador virtual (fase 2). Siguiente: capa 7 (despliegue), ver `07-despliegue`.

Objetivo: lo más seguro posible y con buenas prácticas, sin que nada se escape. La capa se cruzó contra el **OWASP Top 10:2025** (parte 8).

## Plan de la capa 6
1. **Qué protegemos y de quién** (activos y amenazas) — **cerrada**
2. **Autenticación y sesión del panel** — **cerrada**
3. **Autorización y acceso a datos** — **cerrada**
4. **Entradas, archivos y contenido** — **cerrada**
5. **Datos y privacidad** (cifrado, retención, normativa costarricense) — **cerrada**
6. **Infraestructura** (HTTPS, cabeceras, secretos, CORS, límites de frecuencia, bots) — **cerrada**
7. **Monitoreo, copias de seguridad, pruebas de seguridad y respuesta a incidentes** — **cerrada**
8. **Cruce final con OWASP Top 10:2025** — **cerrada**

## Principios que guían todo
- **Mínimo privilegio:** cada pieza (usuario, base de datos, clave) tiene solo los permisos que necesita.
- **Seguro por defecto:** todo queda denegado hasta que se permite explícitamente.
- **Defensa en profundidad:** varias barreras, no una sola.
- **No confiar nunca en el cliente:** el servidor valida y calcula todo lo importante.
- **Privacidad por diseño:** recolectar y guardar lo mínimo necesario.
- **Fallar de forma segura:** un error no debe abrir acceso ni revelar detalles internos.

## Checklist de referencia (imagen "20 cosas", evaluada para NailBook)
Aplican directamente 16 de las 20; 2 no aplican; 2 aplican de otra forma. La lista está pensada para apps que hablan directo con la base de datos desde el navegador; NailBook no lo hace.

| # | Práctica | En NailBook |
|---|---|---|
| 1 | Ocultar API keys | Sí. Claves solo en el servidor; al navegador solo llega lo público |
| 2 | Eliminar secretos de Git | Sí. `.gitignore`, escaneo de secretos y rotar claves filtradas |
| 3 | Key pública para la base de datos | No aplica. La base de datos no es accesible desde internet, solo desde la API |
| 4 | Row-Level Security | No aplica ahora. La autorización vive en la API; usuario de base con permisos mínimos. Reconsiderar si hubiera varias manicuristas |
| 5 | Encriptar datos sensibles | Sí (parte 5) |
| 6 | Forzar la autenticación | Sí. Todo `/api/admin` protegido por defecto |
| 7 | Restringir acceso a registros | Sí. Cada token solo accede a su cita |
| 8 | Bloquear manipulación de campos | Sí, clave. Precio, duración y estado los calcula el servidor, nunca los manda el cliente |
| 9 | Proteger cookies de sesión | Sí: HttpOnly, Secure, SameSite |
| 10 | Hashear contraseñas | Sí (ASP.NET Identity) |
| 11 | Rate limiting | Sí |
| 12 | Protección contra bots | Sí. Riesgo propio: retenciones en masa que bloqueen la agenda |
| 13 | Parametrizar queries | Sí. EF Core lo hace; sin SQL concatenado |
| 14 | Validar inputs | Sí, siempre en el servidor |
| 15 | Sanitizar contenido | Sí. Las notas de la clienta se muestran como texto en el panel (riesgo de XSS) |
| 16 | Restringir archivos | Sí: tipo, tamaño, dimensiones, revisión real del contenido y quitar metadatos (ubicación de las fotos) |
| 17 | Devolver solo datos necesarios | Sí. La disponibilidad nunca revela quién reservó |
| 18 | Security headers | Sí, con permiso de cámara solo en el probador virtual |
| 19 | Forzar HTTPS | Sí, con HSTS |
| 20 | Escanear dependencias | Sí: Dependabot y auditorías de paquetes |

Lo que la lista no cubre y vemos nosotros: autorización (que nadie toque citas ajenas), abuso de la lógica del negocio, CORS y CSRF, mensajes de error, privacidad de datos personales, registros y monitoreo, copias de seguridad, pruebas de seguridad y respuesta a incidentes.

## Parte 1: qué protegemos y de quién (cerrada)

### Activos (qué protegemos)

| Activo | Sensibilidad | Por qué importa |
|---|---|---|
| Secretos: contraseña del panel (hash), cadena de conexión a la base de datos, clave de Cloudinary, claves de firma | Crítica | Con ellos se controla todo el sistema |
| Comprobantes de pago SINPE | Alta | Imágenes con nombre, teléfono y monto |
| Datos personales de clientas: nombre, WhatsApp, correo, historial, notas, fotos de referencia | Alta | Son datos personales protegidos por ley |
| Tokens del enlace "Mi cita" | Media-alta | Dan acceso a una cita |
| Datos del negocio: agenda, ingresos, precios | Media | Información comercial |
| Disponibilidad del servicio (agenda no bloqueada) | Media | Si se abusa, se pierden reservas reales |
| Imagen de la mano en el probador virtual | Baja si se cumple | Privacidad por diseño: se procesa en el dispositivo y no se almacena ni se envía |
| Código fuente | Media | No debe contener secretos |

### Amenazas (de quién)

| Actor | Qué podría intentar |
|---|---|
| Visitante anónimo malicioso | Adivinar tokens, enumerar citas, inyectar contenido en formularios, subir archivos maliciosos |
| Bots y spammers | Crear retenciones en masa para bloquear la agenda, llenar formularios, extraer datos |
| Clienta con mala intención | Ver o modificar la cita de otra, manipular precios o estados, subir un comprobante falso |
| Atacante dirigido al panel | Fuerza bruta, reutilización de contraseñas filtradas, phishing a la manicurista, robo de sesión |
| Error humano (de nosotros o de ella) | Secretos subidos a Git, configuración errónea, sesión abierta en un equipo compartido, borrado accidental |
| Cadena de suministro | Dependencia comprometida (npm, NuGet) o servicio de terceros comprometido (Cloudinary, hosting) |
| Fallos no maliciosos | Caída del servicio o pérdida de datos |

### Superficie de ataque (por dónde pueden entrar)
Endpoints públicos (unos 15), endpoints de administración, formularios y notas, subida de archivos (foto de referencia y comprobante), enlace "Mi cita", login del panel, servicios de terceros (Cloudinary), repositorio y CI/CD, hosting y base de datos, y el navegador de la clienta (cámara del probador).

### Riesgos priorizados (confirmado)
1. Acceso no autorizado al panel (impacto alto).
2. Filtración de comprobantes y datos personales (impacto alto).
3. Abuso de retenciones y bots que bloquean la agenda (probabilidad alta, impacto medio).
4. Manipulación de precios o estados vía API (impacto medio-alto, fácil de prevenir).
5. Secretos filtrados en Git (probabilidad media, impacto alto).
6. Subida de archivos maliciosos (impacto medio).
7. Fraude con comprobantes falsos (impacto económico bajo-medio). Es un riesgo **de proceso**: la manicurista debe confirmar el pago contra su propia cuenta SINPE, no solo con la imagen.
8. Dependencias vulnerables (probabilidad media).

### Decisiones de la parte 1 (confirmadas el 20 nov 2026)
1. **Minimización de datos:** de la clienta se piden solo **nombre y WhatsApp** (obligatorios). El **correo es opcional**; las notificaciones por correo se envían solo si lo dio. Menos datos, menos riesgo y menos obligaciones legales.
2. El orden de prioridad de los riesgos de arriba queda aprobado.

## Parte 2: autenticación y sesión del panel (cerrada)

Contexto: hay un solo usuario administrador (la manicurista), con el modelo preparado para más roles más adelante.

| Tema | Decisión | Por qué |
|---|---|---|
| Mecanismo de sesión | **Cookie de sesión** de ASP.NET Core Identity: `HttpOnly`, `Secure`, `SameSite`, con prefijo `__Host-` (origen único, ver parte 6) | El JavaScript no puede leerla, así que un XSS no la roba, y se puede revocar desde el servidor. Un JWT guardado en el navegador queda expuesto |
| Origen de las peticiones | Frontend y API bajo el mismo dominio con proxy (decidido en la parte 6) | Las cookies necesitan `SameSite` correcto |
| Protección CSRF | `SameSite` + token antifalsificación en toda petición del panel que modifique datos + CORS cerrado | Con cookies, otro sitio podría intentar enviar peticiones en nombre de la manicurista |
| Contraseña | Hash de Identity (PBKDF2). Mínimo **12 caracteres**, se permiten frases largas, sin reglas de "una mayúscula y un símbolo", comprobación contra contraseñas filtradas (Have I Been Pwned por k-anonimato), máximo de 128 caracteres, sin cambio periódico obligatorio | Guía actual de NIST: importa la longitud, no la complejidad artificial |
| Fuerza bruta | **Bloqueo** de 15 minutos tras 5 intentos fallidos, límite de frecuencia por IP en el login, mensaje genérico ("credenciales incorrectas") sin revelar si el usuario existe, y bot-check (Cloudflare Turnstile) tras varios fallos | Evita adivinar contraseñas y enumerar cuentas |
| Segundo factor | **Obligatorio**: aplicación autenticadora (TOTP) más **códigos de recuperación** de un solo uso | El panel es el objetivo más valioso; esto frena el robo de contraseña |
| Duración de sesión | **2 horas de inactividad** y **máximo 12 horas** en total, luego hay que iniciar sesión de nuevo | Cubre una jornada sin dejar sesiones eternas |
| Acciones sensibles | Pedir la contraseña de nuevo para cambiar contraseña, 2FA o correo | Si alguien usa una sesión abierta, no puede tomar la cuenta |
| Cierre y cambios | Cerrar sesión la invalida en el servidor; cambiar la contraseña cierra **todas** las sesiones | Revocación real |
| Creación de la cuenta | **No existe registro público.** El administrador se crea una sola vez por un proceso de instalación controlado | Elimina una ruta de ataque completa |
| Recuperar contraseña | Enlace por correo de un solo uso, vence en 30 minutos, respuesta idéntica exista o no la cuenta, y sigue pidiendo 2FA o código de recuperación | El correo de la manicurista pasa a ser parte de la seguridad: debe estar protegido con 2FA también |
| Alertas | Correo a la manicurista ante un inicio de sesión desde un dispositivo nuevo, un bloqueo de cuenta o un cambio de contraseña o 2FA | Detecta intrusiones temprano |
| Registro de eventos | Se guardan inicios de sesión (éxito y fallo), bloqueos y cambios de credenciales, con fecha, IP y navegador, **sin guardar contraseñas ni tokens** | Auditoría sin exponer secretos |
| Seguro por defecto | Todos los endpoints de `/api/admin` exigen sesión por una política global; lo público se marca explícitamente como anónimo | Un endpoint nuevo olvidado queda protegido, no abierto |
| Roles | Un solo rol hoy (`Owner`), con autorización por políticas para sumar roles limitados más adelante | Escalable sin construir lo que no se usa |

Experiencia del login (también es seguridad): permitir pegar la contraseña y usar gestores de contraseñas (`autocomplete` correcto), botón de mostrar u ocultar, y mensajes claros pero genéricos.

Decisiones confirmadas el 20 nov 2026: sesión por cookie (no JWT), 2FA obligatorio con app autenticadora y códigos de recuperación, y sesión de 2 horas de inactividad con máximo de 12 horas.

## Parte 3: autorización y acceso a datos (cerrada)

La autenticación responde "¿quién eres?"; la autorización responde "¿qué puedes hacer?". El riesgo principal aquí es que alguien acceda o modifique **datos de otra persona** cambiando un ID o un token (en OWASP se llama autorización rota a nivel de objeto, el riesgo número 1 de las APIs).

### Quién puede qué

| Actor | Puede |
|---|---|
| **Anónimo** | Leer catálogo, galería, estudio y disponibilidad; crear una retención (con límites); continuar **su propia** reserva con el token que recibió |
| **Quien tiene el token de una cita** | Ver, reprogramar o cancelar **solo esa cita**, dentro de las reglas de tiempo |
| **Administradora** (con sesión y 2FA) | Todo lo de `/api/admin` |

### A. Tokens de cita
- **Generación:** 32 bytes de un generador criptográficamente seguro (256 bits), codificados en base64url. Se guarda **solo el hash SHA-256** y se compara en tiempo constante.
- **Alcance:** el token solo da ver, reprogramar y cancelar esa cita. El ID público (GUID) por sí solo no da acceso a nada.
- **Vigencia:** válido hasta 7 días después de la cita (`booking_link_valid_days_after`). Después, el enlace deja de funcionar.
- **Respuestas idénticas:** un token inválido, vencido o ajeno devuelve exactamente el mismo 404, para no dar pistas.
- **Pérdida del enlace:** la clienta escribe por WhatsApp y la manicurista **regenera el enlace** desde el panel (`POST /api/admin/bookings/{id}/regenerate-link`), lo que invalida el anterior.
- **Fuga por la URL:** como el token va en la dirección, la página "Mi cita" lleva `Referrer-Policy: no-referrer` y `noindex`, y el servidor **no registra el token** en sus logs (se oculta en los registros).
- Límite de frecuencia sobre las consultas de token.

### B. Controles a nivel de objeto
- Toda consulta pública de una cita se filtra por el hash del token. Las consultas del panel exigen sesión.
- Los endpoints públicos **nunca aceptan** del cliente: IDs de clienta o profesional, precios, duraciones, estados, montos ni pagos. Solo reciben IDs de servicios y extras, y la hora.
- Se validan los servicios y extras: activos, y los extras realmente vinculados a ese servicio. Máximo de servicios por reserva (por ejemplo 5).
- Se usan DTOs de entrada separados de las entidades (evita asignación masiva de campos).

### C. Quién puede cambiar el estado de una cita
Las transiciones se verifican **en el dominio** (en la lógica de la cita), no en los controladores.

| Transición | Quién |
|---|---|
| `hold` → `confirmed` o `pending_payment` | La clienta (con su token), una sola vez |
| `confirmed` → `cancelled` o reprogramada | La clienta dentro de la ventana de 24 horas; la administradora siempre |
| `pending_payment` → `confirmed` o rechazo | **Solo la administradora** |
| `completed`, `no_show`, registrar pago final | **Solo la administradora** |
| `hold` → `expired` | Solo el sistema |

### D. Abuso de la lógica del negocio
- **Retenciones:** máximo 2 activas por WhatsApp y por IP (`max_active_holds_per_customer`), límite de creación por IP, y Cloudflare Turnstile (invisible) al crear la retención.
- **Citas futuras activas:** máximo 3 por WhatsApp (`max_active_bookings_per_customer`).
- Los números de WhatsApp **no se verifican** (no hay API de WhatsApp para enviar códigos). Es un riesgo aceptado: lo mitigan los límites anteriores y que la manicurista confirme por WhatsApp.
- Los valores viven en `setting` (ya reflejados en `02-arquitectura`) y son ajustables.
- Opcional: cabecera `Idempotency-Key` para que un reintento de la red no duplique citas.

### E. Datos expuestos: solo lo necesario
- **Disponibilidad pública:** solo las horas libres, nunca quién reservó.
- **"Mi cita"** (lo que ve quien tiene el enlace): servicios, fecha, hora, estado y precio. De la persona, solo el **nombre de pila** y el **teléfono enmascarado** (por ejemplo `••• 1234`). No muestra correo, notas, foto de referencia ni comprobante. Así, si el enlace llega a un tercero, la fuga es mínima.
- **Panel (manicurista):** ve todo. Los comprobantes y fotos privadas se sirven con URLs firmadas de corta duración, generadas solo después de verificar la sesión (detalle en parte 5).
- **Avisos a la manicurista:** recibe el detalle completo en el panel y un correo de aviso con lo mínimo y un enlace al panel. Los comprobantes **no** se adjuntan a correos.
- **Errores:** mismo mensaje para "no existe" y "no es tuya". IDs públicos como GUID, nunca consecutivos.

### F. Política global y pruebas
- Política de autorización por defecto en toda la API; lo público se marca explícitamente como anónimo.
- **Prueba automática** que recorre todos los endpoints y comprueba que cada uno está en la lista de públicos permitidos o exige sesión. Si alguien agrega un endpoint abierto por error, la prueba falla.
- Pruebas de acceso entre clientas: el token de A nunca puede leer ni tocar la cita de B, y un anónimo no puede llamar a `/api/admin`.

### G. Acceso a la base de datos
- **Dos usuarios de base de datos:** el de la API (solo los permisos de datos que necesita, nunca superusuario ni dueño del esquema) y otro, solo para migraciones, con permisos de estructura.
- Las migraciones se ejecutan en el despliegue, no con el usuario de la API.
- La base de datos no es accesible desde internet (parte 6).

### Decisiones de la parte 3 (confirmadas el 20 nov 2026)
1. Token de 256 bits con hash, vigencia hasta 7 días después de la cita y enlace regenerable por la administradora.
2. "Mi cita" con datos mínimos (nombre de pila y teléfono enmascarado, sin correo, notas ni imágenes). Aclarado: esto solo limita lo que ve quien tiene el enlace; la manicurista recibe comprobantes y notificaciones completos en su panel.
3. Límites anti-abuso: 2 retenciones activas y 3 citas futuras por WhatsApp, y Turnstile invisible al crear la retención (ajustables en `setting`).

## Parte 4: entradas, archivos y contenido (cerrada)

Principio: todo lo que viene del navegador es no confiable y se valida de nuevo en el servidor, aunque el frontend ya lo haya validado.

| Tema | Regla |
|---|---|
| Validación de texto | Cada campo con tipo, largo máximo y formato. Nombre de 2 a 80 caracteres; WhatsApp con formato de Costa Rica (8 dígitos, con o sin +506); notas hasta 500 caracteres; correo con formato válido. Se valida con Zod (frontend) y otra vez en el backend; si no cumple, error claro |
| Inyección SQL | EF Core con consultas parametrizadas. Prohibido concatenar texto en SQL. El SQL escrito a mano (restricción anti doble reserva) va fijo en la migración, nunca con datos de usuario |
| XSS | React escapa el texto por defecto. Regla: **nunca** `dangerouslySetInnerHTML` con datos de clientas; las notas se muestran siempre como texto plano. Segunda barrera: `Content-Security-Policy` estricta (parte 6) |
| Inyección en correos y WhatsApp | Los datos de la clienta no se pegan sin limpiar en asuntos de correo ni en enlaces `wa.me`: se codifican como URL y se quitan saltos de línea |
| Parámetros de la URL | Fechas, IDs y listas se validan por tipo y rango (mes entre hoy y `max_advance_days`); se limita el largo de las listas de servicios y extras |
| Tamaño de peticiones | Límite global del cuerpo (por ejemplo 1 MB para JSON) y límite propio para archivos |
| Archivos aceptados | Foto de referencia y comprobante: **solo imágenes JPG, PNG o WebP** (sin PDF: SINPE y los bancos dan capturas de pantalla, y el PDF es un formato más complejo que aumenta la superficie de ataque). **Máximo 5 MB** por archivo |
| Dimensiones y tiempo de procesamiento *(refuerzo OWASP)* | Además del peso, **límite de dimensiones** (por ejemplo 6000×6000 píxeles) y **tiempo máximo de procesamiento**, para evitar imágenes pequeñas en bytes pero enormes al descomprimirse que agoten la memoria. La librería de imágenes se mantiene actualizada |
| Verificación de archivos | El tipo se comprueba por el **contenido real**, no por la extensión ni por lo que declare el navegador. Las imágenes se vuelven a codificar (elimina código oculto) y se les **quitan los metadatos**, incluida la ubicación GPS. Nombres de archivo generados por el servidor, nunca los originales |
| Dónde se guardan | Almacenamiento privado (Cloudinary en modo privado o equivalente), nunca en la misma ruta que el código ni ejecutables |
| Descargas | Solo por URLs firmadas de corta duración, con `Content-Disposition` y `X-Content-Type-Options: nosniff` |
| Subida abusiva | Límite de subidas por IP y por cita; el comprobante solo se acepta en citas que lo piden; una foto por cita (se reemplaza, no se acumula) |
| Galería | Solo sube la manicurista (con sesión), con subida directa a Cloudinary mediante firma de corta duración que fija tipo y tamaño |
| SSRF *(refuerzo OWASP)* | El servidor **nunca descarga una URL enviada por un usuario**. Si en el futuro hiciera falta, solo con lista blanca de dominios y bloqueo de direcciones internas. Las llamadas salientes (Turnstile, Cloudinary, correo) van a direcciones fijas |
| Errores | Mensajes genéricos al usuario (`ProblemDetails` sin detalles internos); el detalle técnico va solo a los registros. Nada de trazas visibles |

Nota: quitar los metadatos importa porque las fotos de celular suelen traer la ubicación GPS exacta de donde se tomaron; una clienta que sube una foto desde su casa estaría entregando su dirección sin saberlo.

### Decisiones de la parte 4 (confirmadas el 20 nov 2026)
1. Comprobantes **solo como imagen** (JPG, PNG, WebP), sin PDF.
2. Máximo de **5 MB** por archivo.
3. Refuerzos de la parte 8: límite de dimensiones y tiempo de procesamiento de imágenes, y regla de SSRF.

## Parte 5: datos y privacidad (cerrada)

Marco legal: en Costa Rica rige la **Ley 8968** (2011, Protección de la Persona frente al Tratamiento de sus Datos Personales), que aplica la Agencia de Protección de Datos de los Habitantes (**Prodhab**). Está en trámite una reforma integral (proyecto 23.097, "Ley de Protección de Datos Personales"); no pude confirmar su estado actual, así que hay que **revisarlo antes de un lanzamiento real**. Esta sección es de diseño técnico, no asesoría legal: con una clienta real habría que consultar a un abogado (por ejemplo si la base de datos debe inscribirse ante la Prodhab) y a un contador (cuánto tiempo conservar registros de ingresos).

### A. Cifrado
| Dónde | Qué |
|---|---|
| En tránsito | HTTPS en todo (parte 6), también entre la API y la base de datos |
| En reposo (base de datos y archivos) | Cifrado del disco por el proveedor de hosting y de Cloudinary; copias de seguridad cifradas |
| Secretos de la aplicación | **Cifrado a nivel de aplicación** (ASP.NET Data Protection o AES-GCM) para el secreto del 2FA (TOTP) y claves de terceros; las claves de cifrado se guardan aparte de la base de datos |
| Claves de Data Protection *(refuerzo OWASP)* | Las claves que usa ASP.NET para las cookies y los secretos del 2FA se **guardan fuera del contenedor** (base de datos cifrada o almacenamiento persistente) y se respaldan; si no, cada despliegue las pierde: se cierran todas las sesiones y los secretos del 2FA quedan ilegibles. Con plan de rotación |
| WhatsApp y correo de la clienta | **No** se cifran campo por campo: la manicurista debe poder buscarlas en el panel (`customers?q=`) y el cifrado por campo lo impediría o exigiría índices ciegos, una complejidad que no compensa para un solo negocio. Los protege el cifrado en reposo, el acceso mínimo y la retención corta |
| Comprobantes | Almacenamiento privado + URLs firmadas de corta duración |
| Contraseñas | Hash (ya definido en la parte 2) |
| Criptografía propia | Nunca: solo las bibliotecas estándar de la plataforma |

### B. Retención (cuánto tiempo se guarda cada dato)
Valores iniciales, ajustables en `setting` (`retention_*`):

| Dato | Se conserva | Después |
|---|---|---|
| Imagen del comprobante | 90 días tras la fecha de la cita | Se **borra la imagen**; queda el registro del pago (monto, método, fecha) para los ingresos |
| Foto de referencia | 30 días tras la cita | Se borra |
| Citas expiradas o canceladas sin completar | 30 días | Se purgan |
| Datos de la clienta (nombre, WhatsApp, correo, notas) | Mientras tenga actividad; **24 meses** sin citas | Se **anonimizan** (no se borra el historial de ingresos) |
| Registros de seguridad (`security_event`) | 12 meses | Se borran |
| Copias de seguridad | 30 días rotativos | Se sobrescriben; los borrados llegan a las copias al rotar |

Un proceso automático diario aplica estas reglas. Plazo legal para registros contables: por confirmar con un contador.

### C. Derechos de la persona y su flujo
La Ley 8968 reconoce acceso, rectificación, supresión y consentimiento sobre los propios datos. Flujo:
- La clienta lo pide por WhatsApp o por el correo del estudio.
- La manicurista lo gestiona desde el panel: ver los datos de esa clienta, corregirlos (`PUT customers/{id}`) y **anonimizar** (`POST customers/{id}/anonymize`), que reemplaza nombre, WhatsApp, correo y notas, y borra fotos y comprobantes, conservando montos y fechas.
- Se registra la solicitud en `security_event`.
- Meta: responder en un plazo razonable (por ejemplo 10 días hábiles).

### D. Consentimiento y aviso de privacidad
- Página pública **Privacidad** (`/privacidad`, texto en `messages/es.json`), en lenguaje claro: quién es la responsable, qué datos se piden, para qué, cuánto tiempo se guardan, con quién se comparten (proveedores) y cómo ejercer los derechos.
- En el paso 3 del flujo de reserva, un aviso corto con enlace a esa página y una casilla de aceptación **no premarcada**; sin aceptarla no se envía la reserva. Se guarda la fecha de aceptación en `customer`.
- El probador virtual avisa antes de pedir la cámara: la imagen se procesa en el dispositivo y no se envía ni se guarda.

### E. Terceros y transferencias
Proveedores que tocan datos: hosting y base de datos, Cloudinary (imágenes), proveedor de correo, Cloudflare Turnstile. Reglas:
- Se usa el mínimo necesario con cada uno (por ejemplo, el correo de aviso no incluye comprobantes).
- Se listan en el aviso de privacidad.
- Se prefieren servicios con región o contratos de protección de datos claros. Que los servidores estén fuera de Costa Rica implica una transferencia internacional de datos; revisar qué exige la ley si fuera un negocio real.
- **Sin rastreadores de terceros**: sin Google Analytics ni píxeles de publicidad. Tipografías autoalojadas. Si se quiere medir visitas, una herramienta sin cookies. Así no hace falta banner de cookies.

### F. Datos en registros y errores
- Nunca se registran contraseñas, tokens, comprobantes ni contenido de notas.
- WhatsApp y correo se enmascaran en los registros (por ejemplo `••• 1234`).
- Los registros de la aplicación se conservan por tiempo limitado.

### Decisiones de la parte 5 (confirmadas el 20 nov 2026)
1. Cifrado del proveedor más cifrado a nivel de aplicación solo para secretos; WhatsApp y correo sin cifrado por campo.
2. Plazos de retención de la tabla (comprobante 90 días, foto de referencia 30 días, clienta inactiva 24 meses, registros de seguridad 12 meses).
3. Página `/privacidad`, casilla de aceptación en el paso 3, anonimizar en lugar de borrar, sin rastreadores de terceros.
4. Refuerzo de la parte 8: claves de Data Protection fuera del contenedor y respaldadas.

## Parte 6: infraestructura (cerrada)

Lo que protege el entorno donde corre todo. El hosting concreto se decide en la capa 7 (`07-despliegue`); aquí se fijan las reglas que cualquier hosting debe cumplir. **La seguridad no depende de planes de pago**: casi todo son configuraciones, y para un proyecto de portafolio se puede montar con planes gratuitos o casi gratuitos (los límites cambian con el tiempo; se revisan en la capa 7). Con una clienta real habría un costo mensual bajo de hosting y base de datos con copias de seguridad, más el dominio.

### A. Origen único y CORS
- El navegador habla con **un solo origen** (por ejemplo `nailbook.cr`): las rutas `/api/*` se redirigen por un proxy inverso (o `rewrites` de Next.js) hacia ASP.NET. Así la cookie `__Host-` funciona y **CORS queda cerrado**: la API no acepta peticiones de otros orígenes.
- Si algún día hiciera falta otro origen, se agrega por **lista exacta de orígenes**, nunca `*`, y con credenciales solo para ese origen.

### B. HTTPS y cabeceras de seguridad
| Cabecera o regla | Valor |
|---|---|
| HTTPS | Obligatorio; HTTP redirige a HTTPS; TLS 1.2 o superior; conexión cifrada también hacia la base de datos |
| `Strict-Transport-Security` | `max-age` de 1 año, `includeSubDomains` (preload más adelante, cuando todo esté estable) |
| `Content-Security-Policy` | Estricta, con **nonces** (sin `unsafe-inline` ni `unsafe-eval`); `default-src 'self'`; imágenes de `self` y Cloudinary; scripts y marcos de Turnstile solo de `challenges.cloudflare.com`; `frame-ancestors 'none'`; `object-src 'none'`; `base-uri 'self'` |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` en general; `no-referrer` en "Mi cita" |
| `Permissions-Policy` | Cámara, micrófono, geolocalización y similares **desactivados** en todo el sitio, salvo cámara habilitada solo en `/probador` |
| Caché | `Cache-Control: no-store` en el panel, "Mi cita" y respuestas con datos personales |
| Verificación | Meta: nota A en pruebas públicas de cabeceras (Mozilla Observatory o securityheaders.com) y verificación en CI |

### C. Secretos
- Nunca en Git. En el hosting, como **variables de entorno o gestor de secretos**; en tu máquina, `dotnet user-secrets` y `.env.local` ignorado por Git. Se versiona un `.env.example` solo con nombres, sin valores.
- **Secretos distintos** por entorno (desarrollo, staging, producción). Datos reales nunca en desarrollo ni staging.
- Escaneo automático: GitHub secret scanning con push protection y `gitleaks` en CI.
- Plan de rotación: si un secreto se filtra, se **rota de inmediato** (se considera comprometido aunque se borre del historial). Rotación periódica de claves de terceros.
- Mínimo privilegio en cada clave (por ejemplo, la clave de Cloudinary de la API no es la de administración de cuenta).

### D. Límites de frecuencia (rate limiting)
Con el limitador integrado de ASP.NET Core, más un segundo filtro en el borde (ver E). Respuesta `429` con `Retry-After`.

| Zona | Límite inicial (ajustable) |
|---|---|
| Login del panel | 5 intentos por cuenta cada 15 min (ya en parte 2) y 10 por IP por hora |
| Crear retención | 5 por IP por hora (más los máximos de la parte 3) |
| Subir archivos | 10 por IP por hora |
| Consultas de token "Mi cita" | 30 por IP por minuto |
| API pública en general | 120 por IP por minuto |
| API de administración | 300 por sesión por minuto |

Detalle técnico importante: detrás de un proxy, la API debe leer la **IP real** del cliente solo desde cabeceras `Forwarded` de proxies de confianza (configuración `ForwardedHeaders` con lista de proxies); si no, todos los usuarios parecen la misma IP o un atacante falsifica la suya.

### E. Bots y protección en el borde
- **Cloudflare** (plan gratuito) delante del sitio: protección contra ataques de denegación de servicio, reglas básicas de firewall, ocultar la IP real del servidor y certificados.
- Objetivo: el servidor de origen **solo acepta tráfico de Cloudflare**, así no se puede saltar la protección. Algunos hostings gratuitos no lo permiten; cómo se aplica (o qué alternativa se usa) se define en la capa 7.
- **Turnstile** invisible al crear retenciones y tras fallos de login (ya definido); validación del token siempre en el servidor.
- Campo trampa (honeypot) oculto en formularios como capa extra barata.

### F. Red y servidores
- **Base de datos sin acceso público**: solo la API se conecta (red privada o lista blanca de IPs); contraseñas fuertes y usuarios de la parte 3.
- Contenedores sin permisos de administrador, imágenes mínimas y actualizadas, sistema operativo con parches automáticos.
- Producción: **sin Swagger ni OpenAPI público** (o protegido con sesión), sin páginas de error detalladas, sin cabecera `Server` de Kestrel, sin modo depuración.
- Tiempos de espera y límites de tamaño en el servidor para evitar peticiones lentas o enormes.
- Entornos separados: desarrollo, staging (rama `dev`, datos falsos) y producción (rama `main`).
- **Configuración verificable** *(refuerzo OWASP)*: lista de endurecimiento por entorno y una prueba en CI que falla si Swagger está activo en producción, faltan cabeceras o aparecen errores detallados.

### G. Cadena de suministro, integridad y CI/CD
- **Dependabot** semanal para npm, NuGet y GitHub Actions; `npm audit` y `dotnet list package --vulnerable` en CI; archivos de bloqueo (`package-lock.json`) versionados.
- Revisar cada dependencia nueva (mantenimiento, descargas, necesidad real): menos paquetes, menos riesgo.
- *(refuerzo OWASP)* Instalar con `npm ci` (respeta el lockfile) y desactivar scripts de instalación de paquetes cuando sea posible. Solo se cargan scripts de terceros de Cloudflare Turnstile (con CSP) y ningún otro; si hubiera uno externo, con Subresource Integrity (SRI).
- *(refuerzo OWASP)* El despliegue a producción solo sale de `main` por CI, con revisión requerida. **Sin deserialización insegura**: solo `System.Text.Json`, nunca `BinaryFormatter`. Subidas a Cloudinary siempre firmadas.
- GitHub Actions: permisos mínimos del token, acciones fijadas por versión, secretos no expuestos a ramas de forks, protección de ramas (ya en `05-convenciones`).
- Cuenta de GitHub, hosting, Cloudflare, registrador del dominio y correo de la manicurista con **2FA**.

### H. Dominio y correo
- Registros **SPF, DKIM y DMARC** para que los correos de NailBook no se falsifiquen ni caigan en spam; registro **CAA** en el DNS; bloqueo de transferencia del dominio.

### Decisiones de la parte 6 (confirmadas el 20 nov 2026)
1. Origen único: frontend y API bajo el mismo dominio con proxy, CORS cerrado.
2. Cloudflare delante (plan gratuito) como objetivo, con los límites de frecuencia de la tabla; el detalle de aplicación depende del hosting (capa 7).
3. CSP estricta con nonces y el conjunto de cabeceras de la tabla, con meta de nota A.
4. Refuerzos de la parte 8: configuración verificable en CI, instalación de paquetes endurecida, despliegue solo desde `main` y sin deserialización insegura.

## Parte 7: monitoreo, copias, pruebas e incidentes (cerrada)

### A. Monitoreo y registros
**Dos tipos de registro, con propósitos distintos:**

| Registro | Para qué | Dónde |
|---|---|---|
| `security_event` (auditoría) | Saber **quién hizo qué** en temas de seguridad | Tabla en la base de datos |
| Registros de la aplicación (logs técnicos) | Diagnosticar errores y rendimiento | Archivos o servicio de logs (por ejemplo con Serilog, en formato estructurado) |

**Qué guarda `security_event`:** inicio de sesión (éxito y fallo), bloqueo de cuenta, cambios de contraseña o 2FA, uso de códigos de recuperación, regeneración de enlaces de cita, confirmación o rechazo de pagos, cambios de ajustes (precios, horarios, retención), solicitudes de derechos (corregir, anonimizar), accesos denegados, límites de frecuencia alcanzados y archivos rechazados.
Campos: id, fecha y hora (UTC), tipo, quién (administradora o anónimo), IP, navegador, objeto afectado (tipo e id), resultado y detalle breve **sin secretos ni datos personales completos**.
**Solo se agrega, nunca se edita**: el usuario de base de datos de la API tiene permiso de insertar pero **no de modificar ni borrar** esa tabla; solo el proceso de retención (con su propio permiso) borra lo vencido a los 12 meses. Así, si alguien entra a la API, no puede borrar sus huellas.

**Logs técnicos:** estructurados, con identificador de correlación por petición, sin contraseñas, tokens, comprobantes ni notas; teléfonos y correos enmascarados.

**Alertas y vigilancia (herramientas con plan gratuito, por confirmar en la capa 7):**
| Qué | Cómo |
|---|---|
| Sitio caído | Chequeo externo de disponibilidad cada pocos minutos (por ejemplo UptimeRobot o Better Stack) contra un endpoint `/health` que **no revela detalles** |
| Errores de la app | Servicio de errores (por ejemplo Sentry en plan gratuito) con **limpieza de datos personales** activada |
| Señales de ataque | Aviso al desarrollador si hay picos de inicios de sesión fallidos, muchos `429` o muchos 404 de tokens |
| Procesos automáticos | Aviso si falla la limpieza de retenciones, la de retenciones vencidas o el borrado de datos |
| A la manicurista | Correos de la parte 2 (dispositivo nuevo, bloqueo, cambios de credenciales) |

### B. Copias de seguridad
| Tema | Regla |
|---|---|
| Frecuencia | **Diaria** automática de PostgreSQL (con recuperación a un punto en el tiempo si el proveedor la ofrece) |
| Retención | **30 días** rotativos (coherente con la parte 5) |
| Cifrado y ubicación | Cifradas y guardadas en un lugar **distinto** al de la base de datos principal (otra cuenta o región), con acceso restringido |
| Objetivos | Pérdida máxima aceptable de datos: **24 horas**; tiempo máximo para volver a funcionar: **4 horas** |
| Prueba de restauración | Una copia **no vale hasta que se prueba restaurarla**: simulacro cada 3 meses en staging, documentado |
| Imágenes | Las fotos de la galería son el trabajo de la manicurista: se guardan los originales en su propio almacenamiento (su teléfono, Drive o similar); los comprobantes y fotos de referencia son temporales a propósito y no se respaldan a largo plazo |
| Tras restaurar | Detalle sutil: una copia vieja puede traer de vuelta datos ya anonimizados o vencidos. **Después de restaurar se vuelve a ejecutar el proceso de retención y se repiten las anonimizaciones registradas** en `security_event` |

### C. Pruebas de seguridad
Se reparten en cuatro tipos: pruebas de código que escribimos nosotros, herramientas que leen el código, herramientas que atacan la app en marcha, y prácticas sin código (simulacros y revisiones manuales).

**Automáticas (corren en cada Pull Request, en GitHub Actions):**
- Pruebas de las partes 3 y 4: enumeración de endpoints (público o con sesión), acceso entre clientas, transiciones de estado permitidas, tokens (expiración, regeneración que invalida el anterior), validación de entradas, subida de archivos (extensión falsa, tamaño excedido, dimensiones excesivas, metadatos GPS eliminados) y límites de frecuencia.
- **Pruebas de los caminos de error** *(refuerzo OWASP)*: servicio externo caído, base de datos sin conexión, datos nulos o fuera de rango.
- Análisis de código: analizadores de .NET y ESLint con reglas de seguridad, `gitleaks` (secretos) y auditoría de dependencias. CodeQL si el repositorio lo permite sin costo (en repositorios privados puede requerir plan de pago; alternativa: Semgrep gratuito).
- Verificación de cabeceras de seguridad y de configuración (parte 6 F) contra staging.

**Diseño seguro como hábito** *(refuerzo OWASP)*: la plantilla de Pull Request incluye una mini lista de amenazas (¿recibe datos nuevos?, ¿quién puede llamarlo?, ¿qué pasa si alguien lo abusa?). Se aplica a cada función nueva, empezando por el probador virtual en la fase 2.

**Antes de cada versión a `main`:**
- Escaneo dinámico con **OWASP ZAP** (modo baseline) contra staging.
- Lista de revisión manual corta (login, permisos, subida de archivos, cabeceras, secretos).

**Antes del lanzamiento (una vez):** "atacar tu propio sitio" con el OWASP Top 10:2025 como guía y el estándar OWASP ASVS nivel 1 como lista de comprobación; se documenta lo encontrado y corregido, y sirve como parte del caso de estudio del portafolio.

### D. Respuesta a incidentes
**Qué es un incidente:** sospecha de acceso no autorizado, fuga de datos, secreto filtrado, sitio alterado, o pérdida de datos.

**Pasos:** detectar → **contener** (cerrar todas las sesiones, rotar secretos, pausar la función afectada, bloquear IPs) → evaluar (qué datos, qué clientas, con registros) → corregir la causa → recuperar (copias si hace falta) → **notificar** (a la manicurista y a las clientas afectadas; revisar qué exige la Ley 8968 y la reforma sobre avisos de brechas) → análisis posterior sin culpas, documentado.

**Interruptor de emergencia:** ajuste `public_booking_enabled` en `setting` (verdadero por defecto). Apagado, la web pública muestra "reservas en pausa, escríbenos por WhatsApp" mientras se resuelve el problema, sin tumbar el sitio ni el panel.

**Guías cortas (runbooks) en `docs/`:**
1. Secreto filtrado (qué rotar y en qué orden).
2. Cuenta del panel comprometida.
3. La manicurista perdió el celular del 2FA y los códigos de recuperación: restablecimiento manual **por el desarrollador, solo tras verificar su identidad** (en persona o videollamada), con registro del evento.
4. Restaurar desde copia de seguridad (con el detalle de volver a aplicar retenciones).
5. Comprobante falso o fraude de pago.
6. Fuga de datos de clientas (y a quién avisar).

**Guía de seguridad para la manicurista (una página):** gestor de contraseñas, guardar los códigos de recuperación en un lugar seguro y separado, no compartir la sesión ni usarla en equipos ajenos, cerrar sesión al terminar, cuidado con correos o mensajes que imiten a NailBook, y a quién llamar ante cualquier sospecha. Es un riesgo de proceso, no de código, y suele ser el eslabón más débil.

### E. Fallar de forma segura *(refuerzo OWASP A10)*
- **Manejador global de excepciones:** toda excepción no prevista devuelve `ProblemDetails` genérico, sin traza, y queda en los logs.
- **Si falla un servicio externo:**
  - Turnstile caído: el login y la creación de retención **se bloquean con un mensaje amable** ("intenta de nuevo en unos minutos"); nunca se deja pasar sin verificar.
  - Correo caído: **no rompe la reserva**; se reintenta en segundo plano y se avisa por WhatsApp.
  - Cloudinary caído: impide subir fotos pero no reservar.
- **Transacciones:** operaciones críticas (crear retención, confirmar pago, anonimizar) o se completan enteras o no se hace nada.
- **Tiempos de espera y reintentos limitados** en todas las llamadas externas.

### Decisiones de la parte 7 (confirmadas el 20 nov 2026)
1. Registros y monitoreo: `security_event` de solo inserción, logs técnicos sin datos personales, chequeo de disponibilidad, servicio de errores con limpieza de datos y alertas de señales de ataque.
2. Copias de seguridad diarias, 30 días, cifradas y en otra ubicación; metas de 24 horas de pérdida y 4 horas de recuperación; simulacro cada 3 meses; reaplicar retenciones tras restaurar.
3. Pruebas automáticas en cada PR, ZAP antes de cada versión, ataque a tu propio sitio antes del lanzamiento, runbooks en `docs/`, interruptor `public_booking_enabled` y guía de seguridad para la manicurista.
4. Refuerzos de la parte 8: diseño seguro como hábito (plantilla de PR), fallar de forma segura y pruebas de caminos de error.

## Parte 8: cruce final con OWASP Top 10:2025 (cerrada)

El OWASP Top 10:2025 es la versión vigente (publicada en noviembre de 2025, primera actualización desde 2021). Trae dos categorías nuevas (cadena de suministro de software y manejo de condiciones excepcionales); SSRF pasó a formar parte de Broken Access Control. OWASP aclara que la lista es de concienciación, no un estándar de cumplimiento, así que sirve como red para detectar huecos, no como prueba de que "ya está todo". Referencia: https://owasp.org/Top10/2025/

| # | Categoría 2025 | Dónde la cubrimos | Refuerzo integrado |
|---|---|---|---|
| A01 | Control de acceso roto (incluye SSRF) | Parte 3 y 4 | Regla de SSRF (parte 4) |
| A02 | Configuración de seguridad incorrecta | Parte 6 | Configuración verificable en CI (parte 6 F) |
| A03 | Fallos en la cadena de suministro | Parte 6 G | `npm ci`, scripts desactivados, SRI (parte 6 G) |
| A04 | Fallos criptográficos | Parte 5 | Claves de Data Protection persistentes (parte 5 A) |
| A05 | Inyección | Parte 4 | Límite de dimensiones y tiempo de imagen (parte 4) |
| A06 | Diseño inseguro | Partes 1 y 3 | Mini lista de amenazas en cada PR (parte 7 C) |
| A07 | Fallos de autenticación | Parte 2 | Ninguno |
| A08 | Integridad de software y datos | Parte 6 G, `05-convenciones` | Despliegue solo desde `main`, sin deserialización insegura (parte 6 G) |
| A09 | Fallos de registro y alertas | Parte 7 A | Ninguno |
| A10 | Mal manejo de condiciones excepcionales | Partes 4, 6 y 7 | Fallar de forma segura y pruebas de errores (parte 7 C y E) |

### Decisiones de la parte 8 (confirmadas el 20 nov 2026)
1. Los 8 refuerzos quedan integrados en las partes indicadas.
2. Capa 6 cerrada; se pasa a la capa 7 (despliegue). La seguridad se revisa otra vez con el ataque a tu propio sitio antes del lanzamiento y al agregar el probador virtual.

## Pendiente
- Crear `docs/` con los runbooks y la guía de seguridad para la manicurista (en el chat de Documentación o al llegar al despliegue).
- Ataque a tu propio sitio antes del lanzamiento (parte 7 C) y revisión al agregar el probador virtual.
- Revisar el estado de la reforma de la ley de datos (proyecto 23.097) y consultar a un abogado y a un contador si hubiera una clienta real.
