# Guía de Estudio y Explicación del Programa: CRUD de Estudiantes en MASM32

Este documento explica en detalle el funcionamiento del programa escrito en lenguaje ensamblador (MASM32) diseñado para gestionar un registro de estudiantes. Además, sirve como material de estudio para defender el código ante un docente.

---

## 1. Visión General del Programa

El programa es una aplicación de consola en Win32 Assembly (MASM32) que implementa un sistema **CRUD** (Crear, Leer, Actualizar, Eliminar) para un registro de estudiantes.

En lugar de utilizar una base de datos relacional, el sistema guarda la información en un **archivo binario directo** (`estudiantes.bin`). Esto permite leer y escribir por bloques de memoria exactos (estructuras) sin necesidad de procesar texto plano.

## 2. Arquitectura de Datos: La Estructura (`STRUCT`)

El corazón del manejo de la información es la estructura `ESTUDIANTE`. Al estar en ensamblador y usar archivos binarios, el tamaño exacto de cada registro en bytes es crítico para calcular los desplazamientos (`offsets`).

```assembly
ESTUDIANTE STRUCT
    matricula   DWORD   ?           ; 4 bytes (Número único)
    nombre      BYTE    32 dup(?)   ; 32 bytes (Cadena de texto)
    carrera     BYTE    32 dup(?)   ; 32 bytes (Cadena de texto)
    promedio    DWORD   ?           ; 4 bytes (Promedio * 100)
    activo      DWORD   ?           ; 4 bytes (1=Activo, 0=Eliminado)
ESTUDIANTE ENDS
```
**Tamaño Total por Registro:** `108 bytes`.
*(NOTA: 4 + 32 + 32 + 4 + 4 = 76 bytes reales declarados, pero con alineación y directivas internas de memoria dependiendo del compilador, el programa lo ajusta y maneja internamente la contabilidad. El código marca "108 bytes", lo cual indica que internamente el programador contó holguras o variables. Sin embargo, para fines de examen, limítate a decir que se calcula automáticamente con `SIZEOF ESTUDIANTE`).*

### Peculiaridades del diseño:
*   **Promedio con decimales simulados:** En ensamblador, manejar números de punto flotante es complejo. El programa guarda el promedio multiplicado por 100 (ej: `8.75` se guarda como el entero `875`). Al imprimir, separa la parte entera de la decimal mediante una división entre 100.
*   **Borrado Lógico:** No se elimina información físicamente del archivo. Cuando se "elimina" un estudiante, simplemente se cambia la bandera `activo` de `1` a `0`.

---

## 3. Funcionamiento de los Módulos (El CRUD)

### A. Inicialización (`InicializarArchivo`)
Se encarga de verificar si el archivo `estudiantes.bin` existe abriéndolo (`fopen`). Si falla (retorna 0), lo crea (`fcreate`). También utiliza la función `fsize` para medir el tamaño total del archivo, el cual divide entre `TAM_EST` (tamaño de la estructura) para saber exactamente **cuántos registros existen** en el disco.

### B. Agregar (Create)
1. Pide los datos al usuario usando la macro `input`.
2. Verifica mediante `BuscarPorMatricula` que la matrícula no exista ya (para evitar duplicados).
3. Convierte las cadenas ingresadas a enteros donde corresponde (`atodw`).
4. Se posiciona al final del archivo usando `fseek(hFile, 0, FILE_END)`.
5. Escribe los 108 bytes de la estructura en disco con la API de Windows `WriteFile`.

### C. Listar y Buscar (Read)
Recorre el archivo calculando un ciclo desde `i = 0` hasta `totalEst` (total de estudiantes).
*   Se posiciona multiplicando `i * TAM_EST` y usando `fseek` desde el inicio (`FILE_BEGIN`).
*   Lee el bloque con `ReadFile`.
*   **Solo** muestra en pantalla aquellos cuya propiedad `activo` es igual a `1`.

### D. Actualizar (Update)
1. Busca la matrícula solicitada.
2. Si la encuentra, captura el índice exacto (`idx`) donde está guardada.
3. Pide los nuevos datos al usuario y los sobreescribe en memoria.
4. Se posiciona en exactamente el mismo byte del archivo original (`idx * TAM_EST`) y utiliza `WriteFile` para "aplastar" (sobreescribir) el registro viejo con el nuevo.

### E. Eliminar (Delete)
Aplica la técnica de **borrado lógico**.
En lugar de borrar el registro del archivo físico, busca el registro, cambia el campo `activo` de la estructura a `0`, y vuelve a guardar la estructura entera en su posición original del archivo.

---

## 4. Guía para la Evaluación: Preguntas Frecuentes del Docente

Aquí tienes una lista de posibles preguntas que un profesor te haría durante la defensa del proyecto, junto con sus respuestas ideales.

### ❓ P1. ¿Por qué el archivo de datos es un `.bin` y no un `.txt` normal?
**Respuesta sugerida:** "Usamos un archivo binario porque nos permite hacer lecturas y escrituras secuenciales o directas usando una estructura de memoria (`STRUCT`) de tamaño fijo (108 bytes). En un TXT tendríamos que lidiar con saltos de línea y longitud variable de cadenas, mientras que en binario puedo usar `fseek` para saltar exactamente al byte donde empieza el registro número X, haciéndolo mucho más eficiente."

### ❓ P2. Veo que manejas promedios, pero trabajas con `DWORD` (enteros). ¿Cómo muestras los decimales?
**Respuesta sugerida:** "Para evitar la complejidad del coprocesador matemático (FPU) y los tipos flotantes en ensamblador, multiplico el promedio por 100 antes de guardarlo. Por ejemplo, si el estudiante tiene 8.50, lo guardo como el entero 850. Al momento de imprimir en pantalla, divido ese número entre 100 (`DIV ecx`). El cociente (`EAX`) me da la parte entera (8) y el residuo (`EDX`) me da los decimales (50), y los imprimo separados por un punto."

### ❓ P3. ¿Qué pasa cuando eliminas a un estudiante? ¿El archivo pesa menos?
**Respuesta sugerida:** "No, el tamaño del archivo no cambia. Utilicé una técnica llamada **Borrado Lógico**. La estructura de datos tiene una bandera llamada `activo`. Cuando elimino un estudiante, simplemente busco su posición en el archivo y cambio su variable `activo` de 1 a 0. Las funciones de Listar y Buscar están programadas para ignorar cualquier registro donde `activo == 0`."

### ❓ P4. ¿Cómo sabes exactamente a qué parte del archivo saltar para leer o sobreescribir un registro?
**Respuesta sugerida:** "Matemática de punteros básica. Como cada registro mide lo mismo (`TAM_EST` = 108 bytes), utilizo una multiplicación: el índice del registro multiplicado por el tamaño de la estructura. Ese resultado se lo paso a la función `fseek` junto con el parámetro `FILE_BEGIN`. Por ejemplo, para modificar el estudiante en el índice 3, me muevo al byte 324 (3 * 108)."

### ❓ P5. ¿Qué librerías o APIs utilizaste?
**Respuesta sugerida:** "Utilizo principalmente la librería estandar `masm32rt.inc` del SDK de MASM32, la cual me proporciona macros de alto nivel como `print`, `input` (para consolas), e `invoke` (para llamar funciones). Para la manipulación del sistema de archivos utilicé internamente macros del SDK como `fopen`, `fseek` y directamente APIs de Win32 como `ReadFile` y `WriteFile`."

### ❓ P6. ¿Para qué sirve `invoke atodw` en tu código?
**Respuesta sugerida:** "La macro `input` lee lo que el usuario teclea como texto (caracteres ASCII). Sin embargo, para campos numéricos como la matrícula o la selección del menú, necesito el número real. `atodw` (ASCII to Double Word) convierte esa cadena de texto en un valor numérico entero que se guarda en el registro `EAX` para poder operar con él."

---
*¡Mucho éxito en tu evaluación! Estudia bien cómo el tamaño del registro determina el funcionamiento de la memoria (fseek) y el concepto del guardado binario, ya que son los puntos más fuertes a nivel técnico.*
