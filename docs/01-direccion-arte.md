# NailBook — Dirección de arte

Estado: **decidida** (17 nov 2026). Todo es modificable, incluido el nombre.

## Marca
- Nombre: **NailBook** (provisional, se puede cambiar; si cambia, solo se actualiza en este documento y en el código de textos/logo).
- Tono: elegante, cálido, profesional. Sin saturar.

## Dirección
**A (editorial claro) con un toque de B (cinematográfico oscuro) en el hero.**
Prioridad: **ligero y accesible**, mobile primero.

## Paleta (opción 1: rojo cromado)
| Rol | Color |
|---|---|
| Fondo | `#F7F3EF` (blanco perlado cálido) |
| Texto | `#1A1416` (casi negro) |
| Acento único | `#B3122B` (rojo cromado) |
| Apoyo (tarjetas, divisiones) | `#E9DED8` (perla rosado) |

Reglas:
- Un solo color de acento; no se agregan más.
- Comprobar el contraste del acento sobre el fondo (objetivo WCAG AA) al implementar.
- El hero puede usar una variante oscura para el toque cinematográfico (valores por definir en diseño).
- La paleta es una elección del proyecto, **no la identidad de una marca real**.

## Tipografía (Google Fonts, gratuitas)
- Títulos: **Fraunces** (variable).
- Cuerpo: **DM Sans**.
- Solo estas dos familias, con `font-display: swap` y subconjunto latino para mantener la carga ligera.
- Alternativa descartada por ahora: Instrument Serif (un solo peso).

## Interacción firma
El cursor "pule" la pantalla y revela el nail art o el brillo cromado debajo. En táctil, un barrido automático suave o desactivada.

## Movimiento
- Texto que aparece por palabra o letra, con animación tipo resorte (spring), no keyframes planos.
- Hero: polvo de perla/glitter suave (pocas partículas, nada pesado).
- Pantalla de carga: silueta de uña o frasco de esmalte que se llena.
- Transiciones entre secciones: barrida de gloss.
- Secciones apiladas al hacer scroll (inspirado en Kimi, adaptado).
- Niveles de rendimiento por dispositivo (móvil/tablet/escritorio) que reducen efectos.
- Respetar `prefers-reduced-motion`: sin animaciones fuertes y sin partículas.

## Referencia visual
Foto de uñas almendra con lazos rojos cromados y perla sobre base perlada: es **solo un ejemplo de un diseño que la manicurista puede hacer**. Sirve de referencia de acabado y brillo, no de marca.

## Referencias de técnica (solo inspiración, no se copian)
- Sitio de Kimi Antonelli: tokens, resortes, secciones apiladas, texto por palabra/letra, niveles de rendimiento, accesibilidad.
- Escena Vortex: partículas con brillo (solo la idea, mucho más ligera).

## Pendiente
- Logo/símbolo (lazo como posible símbolo).
- Valores exactos del hero oscuro.
- Escala tipográfica y espaciados (design system).
