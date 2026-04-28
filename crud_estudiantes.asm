; ============================================================
;  CRUD ESTUDIANTES EN MASM32 - Archivo Binario
;  Usa CreateFile/ReadFile/WriteFile/SetFilePointer/CloseHandle
;  Compilar: Project -> Console Assemble and Link
; ============================================================
include \masm32\include\masm32rt.inc

; ============================================================
;  ESTRUCTURA  (76 bytes por registro)
; ============================================================
ESTUDIANTE STRUCT
    matricula   DWORD   ?
    nombre      BYTE    32 dup(?)
    carrera     BYTE    32 dup(?)
    promedio    DWORD   ?        ; promedio * 100  ej: 875 = 8.75
    activo      DWORD   ?        ; 1=activo  0=eliminado
ESTUDIANTE ENDS

TAM_EST EQU SIZEOF ESTUDIANTE

; ============================================================
.data
    szArchivo   db  "estudiantes.bin",0

    szMenu      db  13,10,"========================================",13,10
                db  "  CRUD ESTUDIANTES - MASM32 Binario",13,10
                db  "========================================",13,10
                db  "  1. Agregar  estudiante",13,10
                db  "  2. Listar   todos",13,10
                db  "  3. Buscar   por matricula",13,10
                db  "  4. Actualizar estudiante",13,10
                db  "  5. Eliminar  estudiante",13,10
                db  "  6. Salir",13,10
                db  "========================================",13,10
                db  "Opcion: ",0

    pMatricula  db  "Matricula        : ",0
    pNombre     db  "Nombre completo  : ",0
    pCarrera    db  "Carrera          : ",0
    pPromedio   db  "Promedio (0-100) : ",0

    mAgregado   db  13,10,"[OK] Estudiante agregado.",13,10,0
    mActualiz   db  13,10,"[OK] Estudiante actualizado.",13,10,0
    mEliminado  db  13,10,"[OK] Estudiante eliminado.",13,10,0
    mNoEncon    db  13,10,"[!!] Matricula no encontrada.",13,10,0
    mDuplicado  db  13,10,"[!!] Matricula ya existe.",13,10,0
    mSinRegs    db  13,10,"[i]  Sin registros.",13,10,0
    mArchivoOK  db  "[i]  Archivo listo.",13,10,0
    mSalir      db  13,10,"Hasta luego!",13,10,0
    mInvalido   db  13,10,"[!!] Opcion invalida.",13,10,0
    mCabecera   db  13,10
                db  "MATRICULA  NOMBRE                  CARRERA                PROMEDIO",13,10
                db  "---------  ---------------------------  ---------------------------  --------",13,10,0
    mPunto      db  ".",0
    mCRLF       db  13,10,0
    mContinuar  db  13,10,"Presione una tecla...",0
    mCancelar   db  13,10,"Cancelado.",13,10,0
    mConfirmar  db  " Eliminar? (1=Si 0=No): ",0
    mDatosAct   db  13,10,"-- Datos actuales --",13,10,0
    mDatosNuev  db  13,10,"-- Nuevos datos --",13,10,0
    mEtNombre   db  "  Nombre  : ",0
    mEtCarrera  db  "  Carrera : ",0
    mEtPromedio db  "  Promedio: ",0

.data?
    hFile       DWORD   ?
    estActual   ESTUDIANTE <>
    bufInput    BYTE    64 dup(?)
    totalEst    DWORD   ?
    opcion      DWORD   ?
    tmpMat      DWORD   ?
    bRW         DWORD   ?

; ============================================================
;  AbrirArchivo
;    Abre para lectura/escritura. Si no existe, lo crea.
;    Retorna handle en EAX y lo guarda en hFile.
; ============================================================
AbrirArchivo PROC
    ; intentar abrir existente
    invoke CreateFile, addr szArchivo,
           GENERIC_READ or GENERIC_WRITE,
           FILE_SHARE_READ or FILE_SHARE_WRITE,
           NULL, OPEN_EXISTING,
           FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        ; no existe, crear nuevo
        invoke CreateFile, addr szArchivo,
               GENERIC_READ or GENERIC_WRITE,
               FILE_SHARE_READ or FILE_SHARE_WRITE,
               NULL, CREATE_NEW,
               FILE_ATTRIBUTE_NORMAL, NULL
    .endif
    mov hFile, eax
    ret
AbrirArchivo ENDP

; ============================================================
;  InicializarArchivo
; ============================================================
InicializarArchivo PROC
    LOCAL fsize :DWORD

    call AbrirArchivo
    invoke GetFileSize, hFile, NULL
    mov fsize, eax
    invoke CloseHandle, hFile

    xor edx, edx
    mov ecx, TAM_EST
    div ecx
    mov totalEst, eax

    print addr mArchivoOK
    ret
InicializarArchivo ENDP

; ============================================================
;  BuscarPorMatricula PROC mat:DWORD
;    EAX = indice  o  -1
; ============================================================
BuscarPorMatricula PROC mat:DWORD
    LOCAL i   :DWORD
    LOCAL off :DWORD

    call AbrirArchivo
    .if hFile == INVALID_HANDLE_VALUE
        mov eax, -1
        ret
    .endif

    mov i, 0
    .while i < totalEst
        ; offset = i * TAM_EST
        mov eax, i
        mov ecx, TAM_EST
        mul ecx
        mov off, eax
        invoke SetFilePointer, hFile, off, NULL, FILE_BEGIN
        invoke ReadFile, hFile, addr estActual, TAM_EST, addr bRW, NULL

        mov eax, estActual.matricula
        .if eax == mat
            .if estActual.activo == 1
                mov eax, i
                invoke CloseHandle, hFile
                ret
            .endif
        .endif
        inc i
    .endw

    invoke CloseHandle, hFile
    mov eax, -1
    ret
BuscarPorMatricula ENDP

; ============================================================
;  ImprimirPromedio  prom:DWORD
;    guardado *100  =>  875 = "8.75"
; ============================================================
ImprimirPromedio PROC prom:DWORD
    LOCAL ent :DWORD
    LOCAL dec :DWORD

    mov eax, prom
    xor edx, edx
    mov ecx, 100
    div ecx
    mov ent, eax
    mov dec, edx

    print str$(ent)
    print addr mPunto
    .if dec < 10
        print "0"
    .endif
    print str$(dec)
    ret
ImprimirPromedio ENDP

; ============================================================
;  AgregarEstudiante  (CREATE)
; ============================================================
AgregarEstudiante PROC
    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput
    mov tmpMat, eax

    invoke BuscarPorMatricula, tmpMat
    .if eax != -1
        print addr mDuplicado
        ret
    .endif

    invoke RtlZeroMemory, addr estActual, TAM_EST

    print addr pNombre
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.nombre, addr bufInput

    print addr pCarrera
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.carrera, addr bufInput

    print addr pPromedio
    input addr bufInput, 6
    invoke atodw, addr bufInput
    mov ecx, 100
    mul ecx
    mov estActual.promedio, eax

    mov eax, tmpMat
    mov estActual.matricula, eax
    mov estActual.activo, 1

    call AbrirArchivo
    invoke SetFilePointer, hFile, 0, NULL, FILE_END
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, NULL
    invoke CloseHandle, hFile

    inc totalEst
    print addr mAgregado
    ret
AgregarEstudiante ENDP

; ============================================================
;  ListarEstudiantes  (READ ALL)
; ============================================================
ListarEstudiantes PROC
    LOCAL i      :DWORD
    LOCAL hayUno :DWORD
    LOCAL off    :DWORD

    mov hayUno, 0
    print addr mCabecera

    call AbrirArchivo
    .if hFile == INVALID_HANDLE_VALUE
        ret
    .endif

    mov i, 0
    .while i < totalEst
        mov eax, i
        mov ecx, TAM_EST
        mul ecx
        mov off, eax
        invoke SetFilePointer, hFile, off, NULL, FILE_BEGIN
        invoke ReadFile, hFile, addr estActual, TAM_EST, addr bRW, NULL

        .if estActual.activo == 1
            print str$(estActual.matricula)
            print "       "
            print addr estActual.nombre
            print "  "
            print addr estActual.carrera
            print "  "
            invoke ImprimirPromedio, estActual.promedio
            print addr mCRLF
            mov hayUno, 1
        .endif
        inc i
    .endw

    invoke CloseHandle, hFile
    .if hayUno == 0
        print addr mSinRegs
    .endif
    ret
ListarEstudiantes ENDP

; ============================================================
;  BuscarEstudiante  (READ ONE - interactivo)
; ============================================================
BuscarEstudiante PROC
    print addr pMatricula
    input addr bufInput, 10
    invoke atodw, addr bufInput
    mov tmpMat, eax

    invoke BuscarPorMatricula, tmpMat
    .if eax == -1
        print addr mNoEncon
        ret
    .endif

    print addr mCabecera
    print str$(estActual.matricula)
    print "       "
    print addr estActual.nombre
    print "  "
    print addr estActual.carrera
    print "  "
    invoke ImprimirPromedio, estActual.promedio
    print addr mCRLF
    ret
BuscarEstudiante ENDP

; ============================================================
;  ActualizarEstudiante  (UPDATE)
; ============================================================
ActualizarEstudiante PROC
    LOCAL idx :DWORD
    LOCAL off :DWORD

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

    print addr mDatosAct
    print addr mEtNombre
    print addr estActual.nombre
    print addr mCRLF
    print addr mEtCarrera
    print addr estActual.carrera
    print addr mCRLF
    print addr mEtPromedio
    invoke ImprimirPromedio, estActual.promedio
    print addr mCRLF

    print addr mDatosNuev
    print addr pNombre
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.nombre, addr bufInput

    print addr pCarrera
    input addr bufInput, 31
    invoke lstrcpy, addr estActual.carrera, addr bufInput

    print addr pPromedio
    input addr bufInput, 6
    invoke atodw, addr bufInput
    mov ecx, 100
    mul ecx
    mov estActual.promedio, eax

    call AbrirArchivo
    mov eax, idx
    mov ecx, TAM_EST
    mul ecx
    mov off, eax
    invoke SetFilePointer, hFile, off, NULL, FILE_BEGIN
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, NULL
    invoke CloseHandle, hFile

    print addr mActualiz
    ret
ActualizarEstudiante ENDP

; ============================================================
;  EliminarEstudiante  (DELETE logico)
; ============================================================
EliminarEstudiante PROC
    LOCAL idx :DWORD
    LOCAL off :DWORD

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

    print addr estActual.nombre
    print addr mConfirmar
    input addr bufInput, 2
    invoke atodw, addr bufInput
    .if eax != 1
        print addr mCancelar
        ret
    .endif

    mov estActual.activo, 0

    call AbrirArchivo
    mov eax, idx
    mov ecx, TAM_EST
    mul ecx
    mov off, eax
    invoke SetFilePointer, hFile, off, NULL, FILE_BEGIN
    invoke WriteFile, hFile, addr estActual, TAM_EST, addr bRW, NULL
    invoke CloseHandle, hFile

    print addr mEliminado
    ret
EliminarEstudiante ENDP

; ============================================================
;  INICIO
; ============================================================
start:
    cls
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
            print addr mContinuar
            inkey
            cls
        .endif

    .until opcion == 6

    invoke ExitProcess, 0
end start
