# NailBook — Convenciones de código y Git

Estado: **aprobado** el 20 nov 2026 (salvo la sección de nombres, que son valores por defecto ajustables). Actualizado el 25 nov 2026: repositorio **público** y reglas de qué se publica. Actualizado el 27 nov 2026: se alinea con las copias públicas de `docs/`. Este documento es la referencia para el chat de Código y para cualquier chat nuevo.

## Idioma
- **Código en inglés**: variables, funciones, componentes, carpetas, tablas, endpoints y mensajes de commit.
- **Textos visibles en español**, en `web/src/messages/es.json` (la versión en inglés irá en `en.json`).
- Las URLs traducidas son solo un mapeo (carpeta interna `services`, URL pública `/servicios`).

## Repositorio
Un solo repositorio en GitHub con tres carpetas:
```
NailBook/
├── web/     Next.js (frontend)
├── api/     ASP.NET Core (backend)
└── docs/    documentos técnicos del proyecto (ver "Qué va en docs/")
```

### Visibilidad: público (decidido el 25 nov 2026)
**El repositorio es público desde el primer commit.** Motivos:
- Las herramientas de seguridad de GitHub que usa nuestra CI son gratuitas en repositorios públicos y de pago en privados: detección de secretos y protección contra subirlos, revisión de dependencias y CodeQL (escaneo de código).
- Un repositorio público con buena CI e historial de commits ordenado es parte del portafolio.
- El diseño de seguridad no depende de que el código sea secreto.

Consecuencias que se cumplen siempre:
- **El historial es público desde el principio:** ningún secreto, nunca (ver "Secretos").
- **Licencia:** sin licencia explícita (todos los derechos reservados) mientras sea portafolio. Si más adelante se quiere una licencia abierta, se decide en el chat Principal.
- **Si hay clienta real:** se puede pasar el repositorio a privado (cambiar la visibilidad en GitHub); en ese caso hay que decidir cómo reemplazar las herramientas de seguridad que dejan de ser gratuitas (ver `07-despliegue`, sección "Si hay una clienta real").
- **Datos personales o de una clienta real:** nunca en el repositorio (ni en código, ni en pruebas, ni en `docs/`, ni en el historial). Los datos de ejemplo son inventados.
- **Rutas de tu equipo** (por ejemplo la carpeta local donde se clona) no se escriben en ningún documento ni archivo del repositorio.

### Qué va en `docs/`
`docs/` es público. Se copian **solo los documentos técnicos**: `01-direccion-arte`, `02-arquitectura`, `04-roadmap`, `05-convenciones`, `06-seguridad`, `07-despliegue` y `08-herramientas`.
- `00-brief` **no se copia tal cual**. Se publica una versión resumida (qué es el proyecto, alcance, stack).
- `09-chat-codigo` **no se copia**: contiene preferencias personales de trabajo.
- Los runbooks y la guía de seguridad (Fase 9) se escriben sin secretos, sin datos reales y sin direcciones internas.
- Antes de cada copia a `docs/` se revisa que no haya nada de lo anterior.

### Cómo se mantienen las copias
- Los **originales viven en el Project de Claude** y son la fuente. Las copias de `docs/` se derivan de ellos.
- Las únicas diferencias permitidas son las de este apartado (`00-brief` resumido y `09` sin copiar). Si se cambia un original, se actualiza la copia; si se cambia una copia, el cambio se lleva al chat Principal para igualar el original.

## Ramas (aprobado)

| Rama | Para qué |
|---|---|
| `main` | Producción. Protegida: solo recibe cambios desde `dev` por Pull Request. Cada entrega lleva etiqueta de versión |
| `dev` | Integración y pruebas |
| `feature/<nombre>` | Una funcionalidad terminada. Sale de `dev` y vuelve a `dev` por Pull Request |
| `fix/<nombre>` | Una corrección. Sale de `dev` y vuelve a `dev` por Pull Request |
| `hotfix/<nombre>` | Error urgente en producción: sale de `main`, vuelve a `main` y también se copia a `dev` (casi nunca se usa) |

Reglas para que no se multipliquen las ramas:
- **Permanentes: solo 2** (`main` y `dev`). De trabajo: normalmente 1 abierta a la vez, máximo 2 o 3. En GitHub se ven de 3 a 5 ramas.
- **Solo dos prefijos de uso normal:** `feature/` y `fix/` (más `hotfix/` en emergencias).
- **Una rama por tarea terminada**, no por idea ni por commit (por ejemplo `feature/availability-calculator`). En todo el proyecto se crearán unas 40 a 60, todas borradas al integrarse.
- **Se borra al integrar** (activar en GitHub el borrado automático de ramas integradas).
- **Cambios mínimos** (una errata, un ajuste en `docs/`) pueden ir directo a `dev` sin rama.
- Nombres de rama en minúsculas con guiones (`feature/booking-hold-endpoint`).

## Commits
Formato Conventional Commits, en inglés, en imperativo y de máximo 72 caracteres en la primera línea:
- `feat(api): add availability calculator`
- `fix(web): correct slot time zone`
- `docs: update architecture document`
- `refactor(api): extract booking state rules`
- `test(api): cover double booking constraint`
- `chore: update dependencies`

Commits pequeños y frecuentes.

## Pull Requests
- Título con el mismo formato que un commit.
- Descripción corta: qué cambia, por qué y cómo probarlo.
- Para integrarse deben pasar las revisiones automáticas.
- `feature/` y `fix/` hacia `dev`: **squash merge** (un commit limpio por tarea).
- `dev` hacia `main`: **merge commit** (se conserva el historial de la entrega) y se crea la etiqueta de versión.

## Versiones
- Versionado semántico (`v0.1.0`, `v0.2.0`...), `0.x` hasta la primera entrega pública.
- Las etiquetas se crean sobre `main`.
- Archivo `CHANGELOG` actualizado en cada entrega.

## Revisiones automáticas (GitHub Actions)
En cada Pull Request y en cada cambio a `dev` y `main`: estilo (lint), pruebas y compilación, de `web/` y de `api/`. El detalle del flujo de entrega está en `07-despliegue`.

## Protección de ramas
- `main`: Pull Request obligatorio, revisiones automáticas en verde, sin push directo y sin force push.
- `dev`: sin force push y revisiones automáticas activas.

## Secretos
- **Nunca se suben al repositorio** (que es público): archivos `.env`, claves, cadenas de conexión, tokens.
- `.gitignore` desde el primer commit; se sube un `.env.example` con valores falsos.
- **Detección de secretos y protección contra subirlos activadas en GitHub** (gratuitas en repositorios públicos) desde que se crea el repositorio.
- Si una clave se filtra, se rota de inmediato (borrar el commit no basta, porque el historial y las copias ya pudieron ser leídos).

## Nombres (valores por defecto, ajustables)
- Base de datos: `snake_case` (tablas y columnas, como en el modelo de datos).
- JSON de la API: `camelCase`.
- C#: `PascalCase` para tipos y métodos, `camelCase` para variables locales y `_camelCase` para campos privados.
- TypeScript: `camelCase` para variables y funciones, `PascalCase` para componentes, archivos en `kebab-case` (por ejemplo `booking-form.tsx`).

## Borrador de instrucciones para el chat de Código
La versión vigente está en `09-chat-codigo`. Resumen:
- **Fabián escribe el código** siguiendo indicaciones. No se usa Claude Code.
- Se entrega el **código completo** de cada archivo, nunca fragmentos sueltos ni zips (archivos individuales).
- Explicación breve de qué se hizo y por qué.
- **Una etapa a la vez**, esperando confirmación antes de seguir.
- Antes de cada paso se indica **la carpeta exacta** donde se está trabajando.
- Si aparece un error, se explica la causa.
- Se indica cuándo hacer cada commit y con qué mensaje.
- Se siguen estos documentos: `01-direccion-arte`, `02-arquitectura`, `05-convenciones` y `06-seguridad`.
