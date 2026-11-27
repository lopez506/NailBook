# NailBook — Despliegue (capa 7)

Estado (20 nov 2026): **capa 7 completa. Partes 1 a 4 CERRADAS (confirmadas por Fabián). Parte 5 (lista de verificación de salida) escrita, pendiente de su visto bueno final.** Antes se cerró la capa 6 (`06-seguridad`).

Fabián pidió aclarar las herramientas de despliegue desde ya; si más adelante hay que cambiar alguna, se hace en su momento. Por eso el diseño busca **portabilidad**: la API en un contenedor Docker, configuración por variables de entorno y nada atado a un proveedor.

Los datos de planes y precios de abajo se revisaron en noviembre de 2026 y **cambian con frecuencia**: hay que volver a verificarlos justo antes de desplegar.

## Plan de la capa 7
1. **Hosting y herramientas** — CERRADA
2. **Pipeline de CI/CD y entornos** — CERRADA
3. **Dominio, DNS, correo (SPF/DKIM/DMARC) y Cloudflare** — CERRADA
4. **Copias de seguridad y monitoreo** — CERRADA
5. **Lista de verificación de salida a producción** — escrita, por confirmar

## Resumen de herramientas elegidas
| Función | Herramienta | Coste (portafolio) |
|---|---|---|
| Frontend | Vercel Hobby | Gratis (no comercial) |
| API | Contenedor Docker en plataforma gratuita | Gratis (se duerme) |
| Base de datos | Neon gratuito | Gratis |
| CI/CD, registro de imágenes, tareas programadas | GitHub Actions + GHCR | Gratis |
| Dominio y DNS | `.com` en Cloudflare Registrar + DNS Cloudflare + DNSSEC | Unos 8 a 10 USD/año |
| Antibots | Cloudflare Turnstile | Gratis |
| Correo transaccional | Resend (subdominio `mail.`) | Gratis |
| Imágenes | Cloudinary | Gratis |
| Copias cifradas | Cloudflare R2 (bucket privado) | Gratis |
| Disponibilidad y heartbeats | Better Stack | Gratis |
| Errores | Sentry Developer | Gratis |

## Parte 1: hosting y herramientas (CERRADA)

### Decisiones confirmadas por Fabián (20 nov 2026)
1. **Escenario A para el portafolio** (gestionado y gratuito), con diseño portable. Se pasa a B (VPS) o a planes de pago si aparece una clienta real (ver sección "Si hay una clienta real").
2. **Copia nocturna propia** con GitHub Actions: `pg_dump` cifrado a almacenamiento privado, 30 días. Obligatoria en A; también en B (los respaldos del VPS son semanales y viven en el mismo proveedor).
3. **Portabilidad** como regla de diseño: API en Docker, configuración por variables de entorno, sin funciones propias de un proveedor, disponibilidad que no dependa de tareas en segundo plano.

### Qué hay que alojar
| Pieza | Necesidad |
|---|---|
| Frontend (Next.js) | Servidor Node o plataforma con soporte de Next.js |
| API (ASP.NET Core) | Contenedor Docker; debe poder ejecutar tareas automáticas (limpieza de retenciones cada minuto, retención diaria) |
| Base de datos | PostgreSQL con extensión `btree_gist`, sin acceso público |
| Borde | Cloudflare (plan gratuito) delante del sitio |
| Imágenes | Cloudinary (plan gratuito) |
| CI/CD y copias | GitHub Actions |
| Correo | Resend (Parte 3) |

### Lo que se encontró en planes gratuitos (nov 2026)
- **Vercel Hobby:** gratis, pero restringido a uso personal no comercial; todo uso comercial exige plan Pro o Enterprise (Pro, unos 20 USD al mes).
- **API en contenedor:** los servicios gratuitos que mantienen un proceso largo **se duermen** (Render y SnapDeploy tras 15 minutos, Koyeb tras una hora); el primer visitante después de un descanso espera 30 a 60 segundos. Fly.io ya no tiene plan gratuito para cuentas nuevas. Railway da solo 1 USD de crédito mensual en su plan gratuito. Oracle Cloud ofrece una máquina virtual gratuita que **no se duerme**, pero la administra uno mismo y pide tarjeta; hay límites por región. Si Render pide tarjeta o no, las fuentes se contradicen: verificar.
- **PostgreSQL en Neon (plan gratuito):** 1 GB por proyecto, el cómputo se apaga por inactividad y la restauración a un punto en el tiempo cubre solo las **últimas 6 horas**, con 1 snapshot manual y sin snapshots programados. Supabase gratuito se pausa tras una semana sin uso y no incluye copias ni recuperación. Neon de pago (Launch) cobra por uso (unos 0,106 USD por hora de cómputo y 0,35 USD por GB al mes) y permite una ventana de restauración de hasta 7 días.

### Hostinger (consulta de Fabián)
- **Hosting compartido/Web: no sirve** para este proyecto. ASP.NET solo se soporta en planes VPS (los servidores son Linux; una app ASP.NET Core se aloja en un VPS).
- **Hosting Node.js (planes Business y Cloud):** corre Next.js con despliegue desde GitHub, pero las apps se ejecutan bajo demanda y el proceso se detiene tras un periodo sin tráfico. No resuelve la API en .NET.
- **VPS (KVM 1/2): sí sirve y equivale a la Opción B.** Acceso root, plantilla Docker de un clic, firewall, snapshot gratuito y respaldos semanales gratuitos. KVM 1 (1 vCPU, 4 GB RAM, 50 GB NVMe): promoción de unos 4,99 USD/mes con plazo de 24 meses y renovación a unos 8,49 USD/mes; otra fuente independiente lista 12,99 a 19,49 USD/mes. **Verificar precio y plazo antes de comprar.** Los respaldos semanales no cumplen el RPO de 24 h, por eso el `pg_dump` nocturno sigue siendo necesario.
- No comprar plazos largos mientras el proyecto sea solo portafolio.

### Consecuencias para el diseño (importantes)
1. **El sueño de la API afecta la reserva.** Las tareas de limpieza no corren mientras la API duerme. Por eso las consultas de disponibilidad deben **ignorar por sí mismas las retenciones vencidas** (`hold_expires_at` menor que la hora actual), sin depender de que el proceso de limpieza haya corrido; la limpieza real ocurre al guardar una cita nueva (Regla 3) y cuando la API despierte. La retención diaria de datos se dispara con una tarea programada de GitHub Actions que llama a un endpoint protegido.
2. **La política de copias (30 días diarios) no se cumple con la base de datos gratuita sola** (6 horas de restauración). Hay que agregar una copia propia: tarea nocturna de GitHub Actions que haga `pg_dump`, la **cifre** y la suba a un almacenamiento privado distinto al de la base de datos, rotando 30 días.
3. **Cloudflare y el origen:** que el servidor acepte solo tráfico de Cloudflare depende del hosting; en plataformas gestionadas gratuitas puede no ser posible, y se compensa con límites de frecuencia en la API, Turnstile y secreto compartido entre el proxy y la API (cabecera verificada).
4. **Origen único:** el navegador habla solo con el dominio del frontend y Next.js reenvía `/api/*` a la API (`rewrites`) en la Opción A. En una máquina virtual propia, el proxy inverso (Caddy) hace lo mismo.

### Dos escenarios
| | Opción A: gestionado y gratuito (ELEGIDA para el portafolio) | Opción B: máquina virtual propia |
|---|---|---|
| Frontend | Vercel Hobby | En la misma máquina (Node) |
| API | Contenedor en una plataforma gratuita (se duerme) | Docker en la máquina |
| Base de datos | Neon gratuito | PostgreSQL en la máquina |
| Proxy y borde | `rewrites` de Next.js + Cloudflare | Caddy + Cloudflare, firewall solo para Cloudflare |
| Ventajas | Casi cero administración, despliegue desde GitHub | Siempre encendido, control total, cumple el "origen solo de Cloudflare", mucho aprendizaje |
| Desventajas | Arranque en frío, copias propias necesarias, límites que cambian | Hay que mantener el sistema (parches, firewall, copias); pide tarjeta; disponibilidad por región |

## Parte 2: CI/CD y entornos (CERRADA)

### Decisiones confirmadas por Fabián (20 nov 2026)
1. **Tres entornos** (local, staging, producción), con staging en servicios gratuitos. `dev` → staging; `main` → producción con aprobación manual.
2. **Migraciones automáticas en el despliegue**, siempre compatibles con la versión anterior.
3. **Imágenes en GHCR etiquetadas por hash de commit**; la marcha atrás es redesplegar la anterior.
4. **Revisiones de la CI obligatorias** para hacer merge (protección de ramas).

### Entornos
| Entorno | Para qué | Dónde corre | Datos |
|---|---|---|---|
| Local | Programar y probar | PC de Fabián, Docker Compose (PostgreSQL + API) | Datos falsos de ejemplo |
| Staging | Probar el flujo completo antes de publicar | Servicios gratuitos, separados de producción | Solo datos de prueba |
| Producción | El sitio público | Opción A (Vercel + API + Neon) | Reales (en el portafolio, de ejemplo) |

Cada entorno tiene sus **propias** bases de datos, claves y secretos. Nada se comparte entre staging y producción.

### Ramas y despliegue
- `feature/*` y `fix/*` → Pull Request hacia `dev` → corre la CI.
- `dev` → se despliega solo a staging.
- `main` → se despliega a producción tras aprobación manual (cumple "desplegar solo desde `main`").

### Qué revisa la CI en cada Pull Request (GitHub Actions)
- **Frontend:** `npm ci` sin scripts de instalación, lint, tipos de TypeScript, pruebas, build y `npm audit`.
- **API:** `dotnet build`, pruebas, formato y revisión de paquetes NuGet con vulnerabilidades.
- **Contrato API ↔ frontend:** se regeneran los tipos desde OpenAPI y la CI falla si el código no coincide.
- **Seguridad:** detección de secretos subidos por error, revisión de dependencias y CodeQL (verificar su disponibilidad en repos privados).
- **Configuración verificable:** prueba que revisa cabeceras, cookies y CSP (capa 6, parte 6 F).
- **Protección de ramas:** no se puede hacer merge si alguna revisión falla.

### Cómo se publica (CD)
1. Se construye la imagen Docker de la API y se guarda en GHCR con el hash del commit como etiqueta.
2. Se aplican las migraciones de base de datos antes de arrancar la nueva versión.
3. Se despliega la API y el frontend.
4. Prueba de humo: salud de la API y página de inicio.
5. Marcha atrás: redesplegar la imagen anterior.

### Migraciones sin romper nada
Primero se **agrega** (columna nueva, opcional), después el código la usa, y solo en otra publicación se **elimina** lo viejo (expandir y contraer). Así una marcha atrás no deja la API rota. Los cambios destructivos exigen copia manual antes.

### Tareas programadas
- Nocturna: `pg_dump` cifrado → almacenamiento privado (30 días).
- Diaria: llamada al endpoint protegido de retención de datos.
- Ambas con alerta si fallan.

### Secretos
Se guardan en **GitHub Environments** (uno por entorno). El de producción exige aprobación de Fabián. Nunca en el repositorio y rotables sin tocar el código.

## Parte 3: dominio, DNS, correo y Cloudflare (CERRADA)

### Decisiones confirmadas por Fabián (20 nov 2026)
1. **Dominio `.com` comprado en Cloudflare Registrar** cuando se llegue al despliegue (no antes). `.co.cr` o `.cr` solo si hay clienta real que lo quiera.
2. **DNS en Cloudflare con DNSSEC.** En la Opción A se empieza sin proxy (solo DNS) + Turnstile + límites de frecuencia en la API; el proxy completo se activa al verificar la compatibilidad con Vercel o al pasar a B (VPS).
3. **Resend** como proveedor de correo, desde un subdominio, con SPF, DKIM y DMARC progresivo (`none` → `quarantine` → `reject`).
4. **Turnstile** en el formulario de reserva y en el login de admin.

### Dominio
Para el portafolio hace falta un dominio propio (sin él no se prueban Cloudflare, Turnstile ni el correo con SPF/DKIM).
| Opción | Precio aproximado (nov 2026, verificar) | Cuándo |
|---|---|---|
| `.com` en Cloudflare Registrar | A costo, sin recargo; desde unos 8 USD al año | Portafolio |
| `.co.cr` | OVH: 39,99 USD/año; otro registrador: 89 € | Clienta real |
| `.cr` | OVH: 127,09 USD | Clienta real |

El `.cr` se registra con NIC Costa Rica; quien registra queda como titular. Cloudflare Registrar da bloqueo contra transferencias y DNSSEC de un clic.

### DNS y subdominios
- DNS gratuito en Cloudflare. `dominio.com` y `www` para el sitio; `staging.dominio.com` para staging; `mail.dominio.com` para el correo transaccional. La API no tiene subdominio público (origen único).
- **Por verificar:** que el proxy de Cloudflare (nube naranja) delante de Vercel no cause conflictos o pérdida de funciones (consultar la documentación de Vercel antes de activarlo).
- Turnstile gratuito, indicado por Cloudflare para la mayoría de aplicaciones en producción.

### Correo transaccional (Resend)
| Proveedor | Plan gratis | Nota |
|---|---|---|
| **Resend (ELEGIDO)** | 3.000 correos/mes, 100/día, un dominio verificado, 30 días de registros | Plan de pago desde unos 20 USD/mes (sin tope diario) |
| Brevo | 300/día (9.000/mes) | Pone su pie de página en el plan gratis |
| Amazon SES | Sin plan gratuito para cuentas nuevas (desde 21 jul 2026) | Descartado |

Usos: avisos a la manicurista (citas, comprobantes) y confirmaciones si el cliente deja correo. **Autenticación:** subdominio propio para aislar reputación, SPF y DKIM con los registros que da Resend, DMARC progresivo. Opcional: Cloudflare Email Routing para reenviar `contacto@dominio.com` a la manicurista (verificar límites).

## Parte 4: copias de seguridad y monitoreo (CERRADA)

### Decisiones confirmadas por Fabián (20 nov 2026)
1. **Cloudflare R2** para las copias cifradas: bucket privado, clave de acceso solo con permiso de escritura en ese bucket, rotación de 30 días, clave de cifrado guardada aparte.
2. **Simulacro de restauración** automático semanal más manual trimestral.
3. **Better Stack** para disponibilidad y heartbeats de tareas programadas, y **Sentry** (plan Developer) para errores, con la opción de unificar después.
4. **Alertas por correo** para los cuatro casos definidos abajo.

### Almacenamiento de copias
| | Cloudflare R2 (ELEGIDO) | Backblaze B2 (alternativa) |
|---|---|---|
| Gratis | 10 GB/mes, 1 M escrituras, 10 M lecturas, descargas sin costo | Primeros 10 GB; después unos 0,007 USD/GB al mes |
| Descargas | Gratis | Gratis hasta 3 veces lo almacenado, luego 0,01 USD/GB |

Una base pequeña pesa pocos MB: 30 copias caben en 10 GB. Si R2 pidiera tarjeta al activarlo, se verifica en ese momento y B2 queda de alternativa. **La clave de cifrado se guarda separada de las copias** (secretos de GitHub y un respaldo propio fuera de línea): si se pierde, las copias no sirven.

### Simulacro de restauración
- **Semanal y automático:** una tarea de GitHub Actions baja la última copia, la descifra, la restaura en una base temporal y comprueba que las tablas clave tienen datos. Avisa si falla.
- **Trimestral y manual:** restaurar en staging con el runbook y medir el tiempo contra el RTO de 4 horas.

### Monitoreo
| Qué | Herramienta | Detalle |
|---|---|---|
| Disponibilidad (sitio y API) | Better Stack gratis | 10 monitores, revisión cada 3 minutos, alertas por correo y Slack, página de estado, uso comercial permitido |
| Errores del código | Sentry Developer gratis | 5.000 errores/mes, 1 usuario, alertas por correo |
| Tareas programadas | Heartbeat de Better Stack | La tarea avisa al terminar; si no avisa a tiempo, alerta |
| Eventos de seguridad | Tabla `security_event` + resumen diario por correo | Ya existe en el diseño |

UptimeRobot queda descartado: sus condiciones de uso comercial del plan gratuito cambiaron varias veces entre 2024 y 2026 y solo ofrece revisiones cada 5 minutos. Better Stack ofrece también 100.000 excepciones al mes gratis; si Sentry se queda corto, se unifica todo en Better Stack al implementar.

### Alertas definidas
1. El sitio o la API no responden.
2. La copia nocturna o la tarea de retención no corrió.
3. Pico de errores 5xx o de intentos de login fallidos.
4. Certificado o dominio por vencer.

Con la API durmiendo en la Opción A no se usan los monitores para mantenerla despierta: va contra el espíritu del plan gratuito y no sustituye pasar a B si hay clienta.

## Parte 5: lista de verificación de salida a producción (por confirmar)

Se recorre completa antes de publicar. Cada punto se marca con evidencia (captura, resultado de prueba o enlace), no de memoria.

### A. Código y CI
- [ ] Todas las revisiones de la CI en verde en `main` (build, pruebas, lint, tipos, `npm audit`, paquetes NuGet, contrato OpenAPI, detección de secretos, CodeQL).
- [ ] Sin secretos en el historial de Git; las claves usadas en desarrollo se rotaron.
- [ ] Dependencias con versión fijada y `npm ci` sin scripts de instalación.
- [ ] Migraciones probadas en staging y compatibles con la versión anterior.
- [ ] Pruebas de rutas de error pasan (entradas inválidas, fallos de servicios externos, comportamiento "cerrado ante fallos").

### B. Configuración de producción
- [ ] Variables de entorno de producción distintas de staging; ninguna clave compartida entre entornos.
- [ ] Modo depuración apagado; los errores no revelan detalles internos.
- [ ] Cookies `__Host-` con `Secure`, `HttpOnly` y `SameSite`; CSP con nonces y demás cabeceras verificadas por la prueba automática.
- [ ] Claves de Data Protection persistentes (no se pierden al reiniciar).
- [ ] CORS cerrado (origen único) y secreto compartido entre proxy y API verificado.
- [ ] Cuentas de admin con 2FA TOTP activo y códigos de recuperación guardados; sin cuentas ni contraseñas por defecto.
- [ ] Interruptor `public_booking_enabled` probado (apagar y encender).

### C. Infraestructura y borde
- [ ] Dominio comprado, DNSSEC activo y bloqueo de transferencia puesto.
- [ ] HTTPS forzado, SSL en modo estricto y HSTS empezando con un `max-age` corto.
- [ ] Turnstile activo en reserva y login de admin; límites de frecuencia activos.
- [ ] La base de datos no es accesible desde Internet; la API solo responde con el secreto del proxy.
- [ ] Decisión tomada sobre el proxy de Cloudflare según la verificación con Vercel (o B con firewall solo para Cloudflare).

### D. Correo
- [ ] SPF, DKIM y DMARC verificados con una herramienta de prueba; DMARC en `none` al inicio.
- [ ] Correo de prueba llega a la bandeja (no a spam) en al menos dos proveedores.
- [ ] Los enlaces de "Mi cita" y los avisos a la manicurista funcionan de punta a punta.

### E. Datos y copias
- [ ] La copia nocturna corre al menos 7 días seguidos sin fallar.
- [ ] Restauración probada con éxito y tiempo medido contra el RTO de 4 h.
- [ ] Clave de cifrado respaldada fuera de línea y probada (se descifra una copia con ese respaldo).
- [ ] Tarea diaria de retención probada (comprobantes 90 d, fotos 30 d, clientes inactivos 24 meses, eventos de seguridad 12 meses).
- [ ] Política de privacidad y aviso de consentimiento publicados y enlazados.

### F. Monitoreo
- [ ] Monitores de disponibilidad y heartbeats creados y recibiendo datos.
- [ ] Sentry recibe un error de prueba y la alerta llega al correo.
- [ ] Cada alerta definida se **probó a propósito** (se apagó algo y llegó el aviso).
- [ ] Página de estado creada (opcional en portafolio).

### G. Funcionamiento
- [ ] Flujo completo en producción: reservar, subir comprobante, confirmar, cancelar y reprogramar desde "Mi cita".
- [ ] Doble reserva simultánea devuelve 409 (probado con dos pestañas).
- [ ] Retención de 10 min expira bien aunque la API haya estado dormida.
- [ ] Zona horaria de Costa Rica correcta en citas y correos.
- [ ] Lighthouse 90 o más; LCP menor a 2,5 s, CLS menor a 0,1, INP menor a 200 ms.
- [ ] Accesibilidad: navegación solo con teclado, contraste, lector de pantalla en el flujo de reserva.
- [ ] Probado en teléfono real (Android y iOS si es posible).

### H. Seguridad final
- [ ] OWASP ZAP contra staging sin hallazgos críticos o altos pendientes.
- [ ] "Atacar tu propio sitio": intentos manuales de saltarse reglas (cancelar cita ajena, manipular tokens, subir archivo no imagen, saturar reservas) y revisión de `security_event`.
- [ ] Runbooks en `docs/` completos y guía de seguridad de la manicurista entregada.

### I. Día de salida
1. Congelar cambios en `dev`.
2. Hacer una copia manual de la base de datos justo antes.
3. Aprobar el despliegue a producción en GitHub (aprobación manual).
4. Prueba de humo y recorrido del flujo de reserva.
5. Etiquetar la versión en Git (`v1.0.0`).
6. Vigilar las alertas y los registros durante las primeras 24 horas.
7. Tener a mano la marcha atrás: la imagen anterior en GHCR y la copia previa.

### J. Después de salir
- [ ] Primera semana: revisar alertas, errores y `security_event`.
- [ ] Hacer el primer simulacro de restauración manual.
- [ ] Revisar costos y límites de todos los planes gratuitos.
- [ ] Subir DMARC a `quarantine` cuando el tráfico real lo respalde.
- [ ] Volver a verificar precios y límites de esta capa.

## Si hay una clienta real: qué hay que cambiar
Esta lista reúne todo lo que deja de valer cuando el proyecto pase de portafolio a producto vendido. Se mantiene viva: cada capa nueva agrega aquí lo suyo.

### 1. Hosting y planes (partes 1 y 2)
- **Vercel Hobby deja de ser válido** (solo uso no comercial): pasar a Vercel Pro (unos 20 USD/mes) o mover el frontend al VPS.
- **La API no puede dormirse:** el arranque en frío de 30 a 60 s es inaceptable para una clienta. Pasar a **Opción B (VPS, por ejemplo Hostinger KVM 1/2 u otro)** o a un plan de pago siempre encendido.
- **Base de datos:** pasar de Neon gratuito a Neon de pago (ventana de restauración hasta 7 días) o a PostgreSQL en el VPS con sus respaldos. Mantener el `pg_dump` nocturno de 30 días.
- **Cloudflare:** en el VPS, proxy activo y firewall que acepte el origen solo desde Cloudflare (se cumple la regla de seguridad que en A solo se compensa).
- **Cloudinary, correo y monitoreo:** revisar si los límites gratuitos alcanzan con tráfico real; pasar a plan de pago si no.
- **Costos recurrentes:** la clienta (o el contrato) debe cubrir dominio, hosting, correo transaccional y almacenamiento de copias. Definir quién paga y quién es titular de las cuentas.
- **Staging con datos reales:** nunca. Staging sigue con datos de prueba; la aprobación manual de producción pasa a ser un paso de responsabilidad documentado.

### 2. Dominio, correo y cuentas (parte 3)
- **Dominio a nombre de la clienta**, comprado por ella o transferido a su cuenta. Valorar `.co.cr` o `.cr` (NIC Costa Rica) si quiere identidad local; revisar precios y titularidad.
- **Titularidad de cuentas:** que dominio, Cloudflare, hosting, Resend, Cloudinary, R2, Better Stack y Sentry queden a nombre de la clienta (o con acceso compartido claro) y documentar la entrega de credenciales.
- **Correo:** pasar a plan de pago de Resend si se supera 100 correos al día; DMARC en `reject` solo tras observar el tráfico real; buzón propio si la clienta lo necesita (el reenvío de Cloudflare no es un buzón).
- **Proxy de Cloudflare:** activarlo tras verificar la compatibilidad con el hosting elegido.

### 3. Copias y monitoreo (parte 4)
- **Responsable de las alertas:** definir una persona (o contrato de soporte) que reciba y atienda las alertas; en el portafolio las recibe Fabián.
- **Copias:** dos destinos (R2 más una copia en otro proveedor) y vigilar que 10 GB gratis siguen alcanzando; plan de pago si no.
- **Monitoreo:** pasar a planes de pago si hace falta revisión más frecuente o más usuarios (Sentry gratuito permite un solo usuario).
- **Simulacro trimestral** con registro de fecha y resultado, entregado a la clienta.
- **Clave de cifrado:** entregar a la clienta un respaldo fuera de línea y documentar quién la custodia.

### 4. Seguridad (capa 6)
- **Atacar el propio sitio antes de salir** (OWASP ZAP + revisión manual) deja de ser opcional.
- **Simulacro de restauración trimestral** y verificación de que los respaldos cifrados se pueden recuperar.
- **Runbooks en `docs/` y guía de seguridad para la manicurista** escritos y entregados.
- **Alertas reales de monitoreo** que lleguen a una persona responsable, y definir quién responde un incidente.
- **Revisar la seguridad al agregar el probador virtual** (fase 2).

### 5. Legal y datos (Ley 8968 / Prodhab)
- **Consultar a un abogado** para política de privacidad, términos de uso y consentimiento, y para saber si hay que inscribir la base de datos ante la Prodhab.
- **Verificar el estado de la reforma a la ley de protección de datos** (proyecto 23.097); no está confirmado y puede cambiar obligaciones.
- **Revisar las retenciones** (comprobante 90 d, foto de referencia 30 d, cliente inactivo 24 meses, evento de seguridad 12 meses) con el abogado antes de fijarlas como definitivas.
- **Contrato con la clienta:** alcance, propiedad del código y del diseño, soporte, mantenimiento y responsabilidad por los datos.

### 6. Negocio y pagos
- **Contador:** consultar la facturación electrónica y obligaciones tributarias de la manicurista; el sistema no emite facturas.
- **Depósito SINPE:** hoy se valida con un comprobante subido y confirmación manual. Con dinero real, definir el proceso de conciliación y qué pasa con disputas y devoluciones.
- **Notificaciones:** confirmar el canal real (WhatsApp/correo) y sus costos o límites con volumen real.
- **Contenido real:** servicios, precios, fotos, textos y horarios reales de la clienta, además de la traducción al inglés si aplica.

### 7. Operación
- **Soporte y mantenimiento:** quién aplica parches y actualizaciones, con qué frecuencia y cómo se cobra.
- **Verificar de nuevo todos los precios y límites** de esta lista antes de firmar o desplegar.

## Pendiente
- Visto bueno de Fabián a la Parte 5.
- Verificar de nuevo límites y precios antes de desplegar (y la compatibilidad del proxy de Cloudflare con Vercel).
- Siguiente en el proyecto: herramientas y extensiones de trabajo, `04-roadmap`, `docs/` (runbooks y guía de seguridad), logo y design system, instrucciones definitivas de los chats de Diseño y Código.
