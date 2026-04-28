include \masm32\include\masm32rt.inc

; Definicion de la estructura del alumno
Alumno STRUCT
    id DWORD ?
    edad DWORD ?
    calificacion DWORD ?
Alumno ENDS

.data
    archivo db "alumnos.dat", 0
    menuMsg db "--- SISTEMA CRUD ALUMNOS ---", 13, 10
            db "1. Crear / Agregar Alumno", 13, 10
            db "2. Leer Registro de Alumnos", 13, 10
            db "3. Borrar Todos los Registros", 13, 10
            db "4. Salir", 13, 10
            db "Elija una opcion: ", 0
            
    promptId db "Ingrese ID del alumno: ", 0
    promptEdad db "Ingrese Edad del alumno: ", 0
    promptCalf db "Ingrese Calificacion (0-100): ", 0
    
    msgExito db 13, 10, "Operacion realizada con exito.", 13, 10, 0
    msgVacio db 13, 10, "No hay registros para mostrar.", 13, 10, 0
    separador db "-------------------------", 13, 10, 0
    
    lblId db "ID: ", 0
    lblEdad db "Edad: ", 0
    lblCalf db "Calificacion: ", 0

.data?
    opcion dd ?
    hFile dd ?
    bytesNum dd ?
    bufferEntrada db 20 dup(?)
    alumnoTemp Alumno <>

.code
start:
    .while 1
        cls
        print addr menuMsg
        
        ; Capturar entrada estandar y convertir a numero DWORD con atodw
        invoke StdIn, addr bufferEntrada, 20
        invoke atodw, addr bufferEntrada
        mov opcion, eax

        .if opcion == 1
            ; CREATE / UPDATE (Añadir al final)
            mov hFile, fopen(addr archivo)
            .if hFile == -1 || hFile == 0
                mov hFile, fcreate(addr archivo)
            .endif
            
            ; Mover puntero al final para no sobrescribir
            mov eax, fseek(hFile, 0, FILE_END)
            
            print addr promptId
            invoke StdIn, addr bufferEntrada, 20
            invoke atodw, addr bufferEntrada
            mov alumnoTemp.id, eax
            
            print addr promptEdad
            invoke StdIn, addr bufferEntrada, 20
            invoke atodw, addr bufferEntrada
            mov alumnoTemp.edad, eax
            
            print addr promptCalf
            invoke StdIn, addr bufferEntrada, 20
            invoke atodw, addr bufferEntrada
            mov alumnoTemp.calificacion, eax
            
            mov bytesNum, fwrite(hFile, addr alumnoTemp, sizeof Alumno)
            fclose hFile
            
            print addr msgExito
            inkey

        .elseif opcion == 2
            ; READ
            mov hFile, fopen(addr archivo)
            .if hFile != -1 && hFile != 0
                print addr separador
                .while 1
                    mov eax, fread(hFile, addr alumnoTemp, sizeof Alumno)
                    .break .if eax == 0 ; Salir si no hay mas bytes que leer
                    
                    print addr lblId
                    print str$(alumnoTemp.id), 13, 10
                    print addr lblEdad
                    print str$(alumnoTemp.edad), 13, 10
                    print addr lblCalf
                    print str$(alumnoTemp.calificacion), 13, 10
                    print addr separador
                .endw
                fclose hFile
            .else
                print addr msgVacio
            .endif
            inkey
            
        .elseif opcion == 3
            ; DELETE (Borrar archivo binario completo)
            .if rv(exist, addr archivo) != 0
                test fdelete(addr archivo), eax
                print addr msgExito
            .else
                print addr msgVacio
            .endif
            inkey
            
        .elseif opcion == 4
            ; SALIR
            invoke ExitProcess, 0
        .endif
    .endw
end start
