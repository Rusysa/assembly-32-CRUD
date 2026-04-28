; ============================================================
;  CRUD ESTUDIANTES EN MASM32 - Archivo Binario
;  Metodos usados del PDF:
;    - fcreate / fopen / fclose
;    - fread / fwrite / fseek / fsize
;    - .IF / .WHILE / .REPEAT estructuras
;    - Estructuras (STRUCT)
;    - CreateFile / ReadFile / WriteFile / CloseHandle
;    - print / inkey / input / str$ / cls
; ============================================================
include \masm32\include\masm32rt.inc

; ============================================================
;  ESTRUCTURA ESTUDIANTE
;  Tamano total: 4 + 32 + 32 + 32 + 4 + 4 = 108 bytes
; ============================================================
ESTUDIANTE STRUCT
    matricula   DWORD   ?           ; numero de matricula unico
    nombre      BYTE    32 dup(?)   ; nombre completo
    carrera     BYTE    32 dup(?)   ; nombre de la carrera
    promedio    DWORD   ?           ; promedio * 100 (ej: 875 = 8.75)
    activo      DWORD   ?           ; 1=activo  0=eliminado logico
ESTUDIANTE ENDS

TAM_EST     EQU  SIZEOF ESTUDIANTE   ; 108 bytes por registro
ARCHIVO_DB  EQU  "estudiantes.bin"

; ============================================================
.data
    ; ------- MENU -------
    szMenu  db  13,10
            db  "==============================================",13,10
            db  "   CRUD ESTUDIANTES - MASM32 Binario         ",13,10
            db  "==============================================",13,10
            db  "  1. Agregar  estudiante                     ",13,10
            db  "  2. Listar  todos los estudiantes           ",13,10
            db  "  3. Buscar  estudiante por matricula        ",13,10
            db  "  4. Actualizar estudiante                   ",13,10
            db  "  5. Eliminar  estudiante                    ",13,10
            db  "  6. Salir                                   ",13,10
            db  "==============================================",13,10
            db  "Opcion: ",0

    ; ------- PROMPTS -------
    pMatricula  db  "Matricula        : ",0
    pNombre     db  "Nombre completo  : ",0
    pCarrera    db  "Carrera          : ",0
    pPromedio   db  "Promedio (0-100) : ",0

    ; ------- MENSAJES -------
    mAgregado   db  13,10,"[OK] Estudiante agregado correctamente.",13,10,0
    mActualiz   db  13,10,"[OK] Estudiante actualizado correctamente.",13,10,0
    mEliminado  db  13,10,"[OK] Estudiante eliminado del sistema.",13,10,0
    mNoEncon    db  13,10,"[!!] Matricula no encontrada.",13,10,0
    mDuplicado  db  13,10,"[!!] Esa matricula ya existe. Use otra.",13,10,0
    mSinRegs    db  13,10,"[i]  No hay estudiantes registrados.",13,10,0
    mArchivoOK  db  "[i]  Archivo de datos listo.",13,10,0
    mArchError  db  "[ERROR] No se pudo acceder al archivo.",13,10,0
    mSalir      db  13,10,"Hasta luego!",13,10,0
    mInvalido   db  13,10,"[!!] Opcion invalida. Intente de nuevo.",13,10,0

    ; ------- CABECERA TABLA -------
    mCabecera   db  13,10
                db  "MATRICULA   NOMBRE                           CARRERA                          PROMEDIO",13,10
                db  "---------   ------------------------------   ------------------------------   --------",13,10,0
    mFila1      db  "  ",0
    mSep        db  "   ",0
    mCRLF       db  13,10,0
    mPunto      db  ".",0

    ; ------- TITULO -------
    szTitulo    db  "CRUD Estudiantes MASM32",0

.data?
    hFile       DWORD   ?           ; handle del archivo
    estActual   ESTUDIANTE <>       ; buffer de un registro
    bufInput    BYTE    64 dup(?)   ; buffer entrada usuario
    totalEst    DWORD   ?           ; total de registros en disco
    opcion      DWORD   ?
    tmpMat      DWORD   ?
    tmpProm     DWORD   ?
    idxEncon    DWORD   ?           ; indice del registro encontrado
    bRW         DWORD   ?           ; bytes leidos/escritos

; ============================================================
;  InicializarArchivo
;    Crea el .bin si no existe.
;    Cuenta cuantos registros hay.
; ============================================================
InicializarArchivo PROC
    LOCAL flen:DWORD

    mov hFile, fopen(ARCHIVO_DB)
    .if hFile == 0
        mov hFile, fcreate(ARCHIVO_DB)
        fclose hFile
        mov hFile, fopen(ARCHIVO_DB)
    .endif

    ; totalEst = fsize / TAM_EST
    mov flen, fsize(hFile)
    fclose hFile

    mov eax, flen
    xor edx, edx
    mov ecx, TAM_EST
    div ecx
    mov totalEst, eax

    print addr mArchivoOK
    ret
InicializarArchivo ENDP

; ============================================================
;  BuscarPorMatricula(mat:DWORD)
;    Retorna EAX = indice (0-based) si encontrado, -1 si no.
;    Rellena estActual con el registro encontrado.
; ============================================================
BuscarPorMatricula PROC mat:DWORD
    LOCAL i:DWORD

    mov hFile, fopen(ARCHIVO_DB)
    .if hFile == 0
        mov eax, -1
        ret
    .endif

    mov i, 0
    .while i < totalEst
        ; offset = i * TAM_EST
        mov eax, i
        mov ecx, TAM_EST
        mul ecx
        mov cloc, fseek(hFile, eax, FILE_BEGIN)

        invoke ReadFile, hFile, addr estActual, TAM_EST, addr bRW, 0

        mov eax, estActual.matricula
        .if eax == mat && estActual.activo == 1
            mov eax, i
            fclose hFile
            ret
        .endif
        inc i
    .endw

    fclose hFile
    mov eax, -1
    ret
BuscarPorMatricula ENDP

; ============================================================
;  ImprimirPromedio  (promedio guardado como entero * 100)
;    Ej: 875 -> "8.75"  |  100 -> "10.00"  |  0 -> "0.00"
; ============================================================
ImprimirPromedio PROC prom:DWORD
    LOCAL parte_entera:DWORD, parte_decimal:DWORD

    mov eax, prom
    xor edx, edx
    mov ecx, 100
    div ecx                     ; eax=parte entera, edx=decimal

    mov parte_entera, eax
    mov parte_decimal, edx

    print str$(parte_entera)
    print addr mPunto

    ; imprimir dos digitos decimales con cero a la izquierda si < 10
    .if parte_decimal < 10
        print "0"
    .endif
    print str$(parte_decimal)
    ret
ImprimirPromedio ENDP

; ============================================================
;  CREAR - Agregar nuevo estudiante
; ============================================================
AgregarEstudiante PROC

    ; --- matricula ---
    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput
    mov tmpMat, eax

    ; --- verificar duplicado ---
    invoke BuscarPorMatricula, tmpMat
    .if eax != -1
        print addr mDuplicado
        ret
    .endif

    ; --- nombre ---
    print addr pNombre
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.nombre, addr bufInput

    ; --- carrera ---
    print addr pCarrera
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.carrera, addr bufInput

    ; --- promedio (se guarda *100 para conservar 2 decimales) ---
    print addr pPromedio
    input addr bufInput, 6
    invoke atodw, addr bufInput
    ; multiplicar por 100 para guardar decimales como entero
    mov ecx, 100
    mul ecx
    mov tmpProm, eax

    ; --- llenar estructura ---
    mov eax, tmpMat
    mov estActual.matricula, eax
    mov eax, tmpProm
    mov estActual.promedio, eax
    mov estActual.activo, 1

    ; --- escribir al final del archivo ---
    mov hFile, fopen(ARCHIVO_DB)
    .if hFile == 0
        mov hFile, fcreate(ARCHIVO_DB)
    .endif

    mov cloc, fseek(hFile, 0, FILE_END)
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, 0
    fclose hFile

    inc totalEst
    print addr mAgregado
    ret
AgregarEstudiante ENDP

; ============================================================
;  READ - Listar todos los estudiantes activos
; ============================================================
ListarEstudiantes PROC
    LOCAL i:DWORD, hayAlguno:DWORD

    mov hayAlguno, 0
    print addr mCabecera

    mov hFile, fopen(ARCHIVO_DB)
    .if hFile == 0
        print addr mArchError
        ret
    .endif

    mov i, 0
    .while i < totalEst
        mov eax, i
        mov ecx, TAM_EST
        mul ecx
        mov cloc, fseek(hFile, eax, FILE_BEGIN)
        invoke ReadFile, hFile, addr estActual, TAM_EST, addr bRW, 0

        .if estActual.activo == 1
            ; columna matricula (ancho 9)
            print str$(estActual.matricula)
            print "       "

            ; columna nombre (ancho 32)
            print addr estActual.nombre
            print "   "

            ; columna carrera (ancho 32)
            print addr estActual.carrera
            print "   "

            ; columna promedio
            invoke ImprimirPromedio, estActual.promedio
            print addr mCRLF

            mov hayAlguno, 1
        .endif
        inc i
    .endw

    fclose hFile

    .if hayAlguno == 0
        print addr mSinRegs
    .endif
    ret
ListarEstudiantes ENDP

; ============================================================
;  READ - Buscar un estudiante por matricula (interactivo)
; ============================================================
BuscarEstudiante PROC

    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput

    invoke BuscarPorMatricula, eax
    .if eax == -1
        print addr mNoEncon
        ret
    .endif

    ; mostrar el registro encontrado
    print addr mCabecera
    print str$(estActual.matricula)
    print "       "
    print addr estActual.nombre
    print "   "
    print addr estActual.carrera
    print "   "
    invoke ImprimirPromedio, estActual.promedio
    print addr mCRLF
    ret
BuscarEstudiante ENDP

; ============================================================
;  UPDATE - Actualizar datos de un estudiante
; ============================================================
ActualizarEstudiante PROC
    LOCAL idx:DWORD

    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput
    mov tmpMat, eax

    invoke BuscarPorMatricula, tmpMat
    .if eax == -1
        print addr mNoEncon
        ret
    .endif
    mov idx, eax        ; guardar indice para reescribir

    ; mostrar datos actuales
    print 13,10,"Datos actuales:",13,10,0
    print "  Nombre  : "
    print addr estActual.nombre
    print addr mCRLF
    print "  Carrera : "
    print addr estActual.carrera
    print addr mCRLF
    print "  Promedio: "
    invoke ImprimirPromedio, estActual.promedio
    print addr mCRLF
    print 13,10,"Nuevos datos:",13,10,0

    ; nuevo nombre
    print addr pNombre
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.nombre, addr bufInput

    ; nueva carrera
    print addr pCarrera
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.carrera, addr bufInput

    ; nuevo promedio
    print addr pPromedio
    input addr bufInput, 6
    invoke atodw, addr bufInput
    mov ecx, 100
    mul ecx
    mov estActual.promedio, eax

    ; sobreescribir en la misma posicion
    mov hFile, fopen(ARCHIVO_DB)
    mov eax, idx
    mov ecx, TAM_EST
    mul ecx
    mov cloc, fseek(hFile, eax, FILE_BEGIN)
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, 0
    fclose hFile

    print addr mActualiz
    ret
ActualizarEstudiante ENDP

; ============================================================
;  DELETE - Eliminar estudiante (borrado logico: activo = 0)
; ============================================================
EliminarEstudiante PROC
    LOCAL idx:DWORD

    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput
    mov tmpMat, eax

    invoke BuscarPorMatricula, tmpMat
    .if eax == -1
        print addr mNoEncon
        ret
    .endif
    mov idx, eax

    ; confirmar eliminacion
    print 13,10,"Eliminar a: "
    print addr estActual.nombre
    print " ? (1=Si / 0=No): ",0
    input addr bufInput, 2
    invoke atodw, addr bufInput
    .if eax != 1
        print 13,10,"Operacion cancelada.",13,10,0
        ret
    .endif

    ; marcar como inactivo
    mov estActual.activo, 0

    mov hFile, fopen(ARCHIVO_DB)
    mov eax, idx
    mov ecx, TAM_EST
    mul ecx
    mov cloc, fseek(hFile, eax, FILE_BEGIN)
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, 0
    fclose hFile

    print addr mEliminado
    ret
EliminarEstudiante ENDP

; ============================================================
;  PUNTO DE ENTRADA
; ============================================================
start:
    cls
    invoke GetConsoleWindow
    invoke SetWindowText, eax, addr szTitulo

    call InicializarArchivo

    .repeat
        print addr szMenu
        input addr bufInput, 2
        invoke atodw, addr bufInput
        mov opcion, eax

        cls

        .if opcion == 1
            print "--- AGREGAR ESTUDIANTE ---",13,10,0
            call AgregarEstudiante

        .elseif opcion == 2
            print "--- LISTA DE ESTUDIANTES ---",13,10,0
            call ListarEstudiantes

        .elseif opcion == 3
            print "--- BUSCAR ESTUDIANTE ---",13,10,0
            call BuscarEstudiante

        .elseif opcion == 4
            print "--- ACTUALIZAR ESTUDIANTE ---",13,10,0
            call ActualizarEstudiante

        .elseif opcion == 5
            print "--- ELIMINAR ESTUDIANTE ---",13,10,0
            call EliminarEstudiante

        .elseif opcion == 6
            print addr mSalir

        .else
            print addr mInvalido
        .endif

        .if opcion != 6
            print 13,10,"Presione una tecla para continuar...",0
            inkey
            cls
        .endif

    .until opcion == 6

    invoke ExitProcess, 0
end start
