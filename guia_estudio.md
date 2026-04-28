# Guía de Estudio y Explicación del Programa: CRUD de Alumnos en MASM32

Este documento explica en detalle el funcionamiento del programa escrito en lenguaje ensamblador (MASM32) diseñado para gestionar un registro de alumnos. Además, sirve como material de estudio para defender el código ante un docente.

---

## 1. Visión General del Programa

El programa es una aplicación de consola en Win32 Assembly (MASM32) que implementa un sistema **CRUD** (Crear, Leer, Actualizar, Eliminar) básico para un registro de alumnos.

En lugar de utilizar una base de datos relacional, el sistema guarda la información en un **archivo de acceso secuencial** (`alumnos.dat`). Esto permite leer y escribir por bloques de memoria exactos (estructuras) sin necesidad de procesar texto plano.

## 2. Arquitectura de Datos: La Estructura (`STRUCT`)

El corazón del manejo de la información es la estructura `Alumno`. Al estar en ensamblador y usar archivos de este tipo, el tamaño exacto de cada registro en bytes es crítico para las operaciones de lectura y escritura.

```assembly
Alumno STRUCT
    id           DWORD ?        ; 4 bytes (Identificador único)
    nombre       db 32 dup(?)   ; 32 bytes (Cadena de texto)
    apellido     db 32 dup(?)   ; 32 bytes (Cadena de texto)
    edad         DWORD ?        ; 4 bytes (Edad del alumno)
    calificacion DWORD ?        ; 4 bytes (Calificación del alumno)
Alumno ENDS
```
**Tamaño Total por Registro:** `76 bytes`.
*(Se calcula sumando: 4 + 32 + 32 + 4 + 4).*

### Peculiaridades del diseño:
*   **Lectura Secuencial:** El archivo se lee desde el inicio bloque a bloque utilizando la macro `fread` de la librería de MASM32.
*   **Borrado Físico con Archivo Temporal:** Cuando se elimina un alumno, no se usa borrado lógico. El programa crea un archivo temporal (`temp.dat`), lee todos los registros de `alumnos.dat` y escribe en el temporal solo los que **no** coinciden con el ID a eliminar. Luego borra el archivo original y renombra el temporal usando la API `MoveFile`.

---

## 3. Funcionamiento de los Módulos (El CRUD)

### A. Agregar (Create)
1. Intenta abrir el archivo `alumnos.dat` con `fopen`. Si falla (retorna -1 o 0), lo crea con `fcreate`.
2. Se posiciona al final del archivo usando `fseek(hFile, 0, FILE_END)`.
3. Pide los datos al usuario mediante `invoke StdIn`.
4. Convierte las cadenas numéricas (como el ID o la edad) a valores enteros de 32 bits usando `invoke atodw`.
5. Escribe la estructura completa en el disco con la macro `fwrite` pasando como parámetro `sizeof Alumno`.

### B. Listar Todos (Read)
1. Abre el archivo en modo lectura.
2. Imprime un separador e inicia un ciclo (`.while 1`).
3. Lee bloque por bloque (`fread`) usando el tamaño de la estructura `Alumno`. Si la lectura devuelve 0, el ciclo termina (`.break`).
4. Imprime en pantalla cada campo del alumno (convirtiendo los números de vuelta a texto con la macro `str$`).

### C. Buscar por ID (Read)
1. Pide al usuario el ID a buscar y lo guarda en `targetId`.
2. Abre el archivo e inicia un ciclo secuencial igual que al listar.
3. Compara el `id` del bloque recién leído con `targetId`.
4. Si coincide, imprime los datos y rompe el ciclo prematuramente (`.break`).
5. Se apoya de una variable bandera (`found`) para saber si al final debe mostrar un mensaje de "no encontrado".

### D. Eliminar por ID (Delete)
Aplica la técnica de **filtro por archivo temporal**.
1. Pide el ID a eliminar.
2. Abre `alumnos.dat` para lectura y crea `temp.dat` para escritura.
3. Lee registro por registro de `alumnos.dat`.
4. Si el ID **no es** el que se quiere borrar, escribe ese registro en `temp.dat`.
5. Si el ID **es** el buscado, activa la bandera `found` en 1 y no lo escribe en `temp.dat` (lo omite).
6. Cierra ambos archivos.
7. Elimina `alumnos.dat` original con `fdelete`.
8. Usa `invoke MoveFile` para renombrar `temp.dat` como `alumnos.dat`.

### E. Borrar Todo
Utiliza la macro `rv(exist, ...)` para verificar la existencia del archivo y la macro `fdelete` para eliminar directamente el archivo completo del disco de un solo paso.

---

## 4. Guía para la Evaluación: Preguntas Frecuentes del Docente

Aquí tienes una lista de posibles preguntas que un profesor te haría durante la defensa del proyecto, junto con sus respuestas ideales.

### ❓ P1. ¿Por qué el archivo de datos es un `.dat` y no un `.txt` normal?
**Respuesta sugerida:** "Usamos un enfoque que permite hacer escrituras directas del bloque de memoria (`STRUCT`) de 76 bytes en binario. En un TXT tendríamos que lidiar con saltos de línea, conversión de caracteres y longitudes variables para cada campo numérico, mientras que así usamos macros como `fwrite` para volcar directamente la estructura entera desde RAM al disco duro en una sola operación."

### ❓ P2. ¿Cómo solucionaste la eliminación de registros de un archivo?
**Respuesta sugerida:** "Utilicé una técnica de filtro mediante un archivo temporal. Al seleccionar Eliminar, el programa abre el archivo maestro en modo lectura y crea un nuevo archivo temporal. Va leyendo registro por registro, y solamente escribe en el temporal aquellos cuyo ID no coincide con el que queremos eliminar. Finalmente, se borra el archivo viejo y se renombra el temporal con el nombre original usando la API de Windows `MoveFile`."

### ❓ P3. ¿Cómo lees o navegas por los registros?
**Respuesta sugerida:** "Las lecturas se hacen de forma secuencial. Por ejemplo, al Listar o Buscar, implementé un ciclo (`.while 1`) en el que la macro `fread` lee exactamente el tamaño de mi estructura (`sizeof Alumno`). Cada lectura avanza el puntero interno del archivo automáticamente. Si busco algo específico, simplemente comparo el `id` cargado en memoria en cada pasada."

### ❓ P4. ¿Qué librerías o macros utilizaste?
**Respuesta sugerida:** "Utilizo principalmente la librería estándar `masm32rt.inc` del SDK de MASM32, la cual me proporciona funciones de alto nivel. Para la consola utilizo `StdIn` y la macro `print`. Para convertir números empleo `atodw` y `str$`. Para el manejo de archivos empleo las macros `fopen`, `fread`, `fwrite`, `fdelete` y `fseek`. Además de la API estándar de Win32 `MoveFile` que llamo con `invoke`."

### ❓ P5. ¿Para qué sirve `invoke atodw` en tu código?
**Respuesta sugerida:** "La función `StdIn` lee lo que el usuario teclea como texto (caracteres ASCII). Sin embargo, para campos numéricos como el ID, la edad, o la calificación, necesito trabajar con el valor numérico de 32 bits real. `atodw` (ASCII to Double Word) convierte esa cadena de texto en un número entero que retorna en el registro `EAX`, el cual luego almaceno en la propiedad correspondiente de la estructura."

---
*¡Mucho éxito en tu evaluación! Estudia bien el flujo del guardado de bloques y especialmente el algoritmo de eliminación con archivo temporal, ya que son los puntos más críticos y diferentes a las bases de datos relacionales tradicionales.*
## 5. Conceptos Clave de Ensamblador (MASM32)

Para entender completamente cómo funciona el código a bajo nivel y poder explicarlo con seguridad, es importante tener claros los siguientes conceptos de lenguaje ensamblador presentes en el programa:

### Registros del Procesador (`EAX`, `EDX`)
Los registros son pequeñas y rapidísimas zonas de memoria dentro del propio procesador. 
*   **EAX (Acumulador):** Es el más importante en este código. Por convención en Win32, casi todas las funciones y macros (como `atodw`, `fopen`, `fread`) devuelven su resultado dejándolo en `EAX`. Por eso verás constantemente líneas como `mov hFile, eax` o `mov targetId, eax` justo después de llamar a una función para guardar su resultado.
*   **EDX:** Se utiliza como un registro de propósito general. En la función de búsqueda de este código se usa como una "bandera" (flag) temporal (`mov edx, 1`) para saber si el ID actual coincide con el buscado o no.

### Punteros y Direcciones de Memoria (`addr`)
En ensamblador no puedes simplemente pasar variables complejas (como arreglos de texto o estructuras enteras) a las funciones directamente. Tienes que pasar la **dirección de memoria** donde comienzan a existir. 
La directiva `addr` (Address) hace exactamente eso. Cuando ves `invoke StdIn, addr buffer, 64`, le estás diciendo a la función: *"Aquí está la dirección de memoria donde empieza mi variable buffer, escribe ahí los próximos 64 bytes que teclee el usuario"*.

### Tipos de Datos: `DWORD`, `db` y `dup(?)`
*   **DWORD (Double Word):** Representa un valor de 32 bits (4 bytes). Se usa para números enteros (como `id`, `edad`, `calificacion`) y también para guardar los "manejadores" de archivos (handles) que Windows nos da, como `hFile`.
*   **db (Define Byte):** Reserva 1 byte de memoria (8 bits). En el programa se utiliza en conjunto con arreglos para formar cadenas de texto (ej. `nombre db 32 dup(?)`).
*   **dup(?):** Significa "Duplicar". La instrucción `32 dup(?)` reserva 32 espacios (en este caso bytes, por el `db`) sin inicializar (eso significa el `?`). Es el equivalente exacto a declarar un array de caracteres vacío en C (`char nombre[32];`).

### Directivas de Control de Flujo (`.if`, `.elseif`, `.while`)
El lenguaje ensamblador puro utiliza etiquetas y saltos condicionales (`cmp`, `jmp`, `je`, `jne`) que hacen que el código sea difícil de leer (código espagueti). Sin embargo, MASM32 proporciona "directivas de alto nivel" como `.if`, `.elseif` y `.while` / `.endw`. Estas directivas son traducidas automáticamente por el compilador (`ml.exe`) a los saltos nativos del procesador, permitiéndote programar casi como si estuvieras en C o C++.

### Llamadas a Funciones (`invoke` vs Macros)
*   **invoke:** Es una directiva de MASM que facilita enormemente llamar a funciones de la API de Windows (como `MoveFile`, `StdIn` o `ExitProcess`). Tras bambalinas, se encarga de "empujar" (hacer `PUSH`) de los parámetros a la pila de memoria (stack) en el orden correcto antes de ejecutar la llamada (`CALL`).
*   **Macros (como `print`, `fopen`, `fwrite`):** Son fragmentos de código preescritos incluidos en la librería de MASM32 (`masm32rt.inc`). Al compilar, el ensamblador reemplaza la palabra de la macro por varias líneas de código real de ensamblador, haciendo que el código fuente quede mucho más limpio y legible.
