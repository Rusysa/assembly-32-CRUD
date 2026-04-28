include \masm32\include\masm32rt.inc

; Estructura expandida segun la notacion de miembros y tamaño
Alumno STRUCT
    id           DWORD ?
    nombre       db 32 dup(?)
    apellido     db 32 dup(?)
    edad         DWORD ?
    calificacion DWORD ?
Alumno ENDS

.data
    archivo      db "alumnos.dat", 0
    archivoTemp  db "temp.dat", 0
    menuMsg      db "--- CRUD AVANZADO DE ALUMNOS ---", 13, 10
                 db "1. Agregar Alumno", 13, 10
                 db "2. Listar Todos", 13, 10
                 db "3. Buscar por ID", 13, 10
                 db "4. Eliminar por ID", 13, 10
                 db "5. Borrar Todo", 13, 10
                 db "6. Salir", 13, 10
                 db "Seleccion: ", 0
            
    pId          db "ID: ", 0
    pNom         db "Nombre: ", 0
    pApe         db "Apellido: ", 0
    pEdad        db "Edad: ", 0
    pCalf        db "Calificacion: ", 0
    
    mExito       db 13, 10, "Operacion exitosa.", 13, 10, 0
    mNoEncontrado db 13, 10, "Registro no encontrado o vacio.", 13, 10, 0
    sep          db "-------------------------", 13, 10, 0

.data?
    opcion       dd ?
    targetId     dd ?
    hFile        dd ?
    hTemp        dd ?
    found        dd ?
    buffer       db 64 dup(?)
    alumnoTemp   Alumno <>

.code
start:
    .while 1
        cls
        print addr menuMsg
        invoke StdIn, addr buffer, 64
        invoke atodw, addr buffer
        mov opcion, eax

        .if opcion == 1
            ; AGREGAR (Append)
            mov hFile, fopen(addr archivo)
            .if hFile == -1 || hFile == 0
                mov hFile, fcreate(addr archivo)
            .endif
            
            mov eax, fseek(hFile, 0, FILE_END)
            
            print addr pId
            invoke StdIn, addr buffer, 64
            invoke atodw, addr buffer
            mov alumnoTemp.id, eax
            
            print addr pNom
            invoke StdIn, addr alumnoTemp.nombre, 32
            
            print addr pApe
            invoke StdIn, addr alumnoTemp.apellido, 32
            
            print addr pEdad
            invoke StdIn, addr buffer, 64
            invoke atodw, addr buffer
            mov alumnoTemp.edad, eax
            
            print addr pCalf
            invoke StdIn, addr buffer, 64
            invoke atodw, addr buffer
            mov alumnoTemp.calificacion, eax
            
            mov eax, fwrite(hFile, addr alumnoTemp, sizeof Alumno)
            fclose hFile
            print addr mExito
            inkey

        .elseif opcion == 2 || opcion == 3
            ; LISTAR O BUSCAR
            mov found, 0
            .if opcion == 3
                print addr pId
                invoke StdIn, addr buffer, 64
                invoke atodw, addr buffer
                mov targetId, eax
            .endif

            mov hFile, fopen(addr archivo)
            .if hFile != -1 && hFile != 0
                print addr sep
                .while 1
                    mov eax, fread(hFile, addr alumnoTemp, sizeof Alumno)
                    .break .if eax == 0
                    
                    mov edx, 0
                    .if opcion == 3
                        mov eax, alumnoTemp.id
                        .if eax != targetId
                            mov edx, 1 ; No es el que buscamos
                        .endif
                    .endif

                    .if edx == 0
                        print addr pId
                        print str$(alumnoTemp.id), 13, 10
                        print addr pNom
                        print addr alumnoTemp.nombre, 13, 10
                        print addr pApe
                        print addr alumnoTemp.apellido, 13, 10
                        print addr pEdad
                        print str$(alumnoTemp.edad), 13, 10
                        print addr pCalf
                        print str$(alumnoTemp.calificacion), 13, 10
                        print addr sep
                        mov found, 1
                        .break .if opcion == 3
                    .endif
                .endw
                fclose hFile
                .if opcion == 3 && found == 0
                    print addr mNoEncontrado
                .endif
            .else
                print addr mNoEncontrado
            .endif
            inkey

        .elseif opcion == 4
            ; ELIMINAR INDIVIDUAL (Filtro via archivo temporal)
            print addr pId
            invoke StdIn, addr buffer, 64
            invoke atodw, addr buffer
            mov targetId, eax
            
            mov hFile, fopen(addr archivo)
            .if hFile != -1 && hFile != 0
                mov hTemp, fcreate(addr archivoTemp)
                mov found, 0
                .while 1
                    mov eax, fread(hFile, addr alumnoTemp, sizeof Alumno)
                    .break .if eax == 0
                    
                    mov eax, alumnoTemp.id
                    .if eax != targetId
                        mov eax, fwrite(hTemp, addr alumnoTemp, sizeof Alumno)
                    .else
                        mov found, 1
                    .endif
                .endw
                fclose hFile
                fclose hTemp
                
                mov eax, rv(exist, addr archivo)
                .if eax != 0
                    test fdelete(addr archivo), eax
                .endif
                
                ; MoveFile es de la API estandar de Windows, por lo que aqui si usamos invoke
                invoke MoveFile, addr archivoTemp, addr archivo
                
                .if found == 1
                    print addr mExito
                .else
                    print addr mNoEncontrado
                .endif
            .else
                print addr mNoEncontrado
            .endif
            inkey

        .elseif opcion == 5
            ; BORRAR TODO
            mov eax, rv(exist, addr archivo)
            .if eax != 0
                test fdelete(addr archivo), eax
                print addr mExito
            .else
                print addr mNoEncontrado
            .endif
            inkey

        .elseif opcion == 6
            invoke ExitProcess, 0
        .endif
    .endw
end start
