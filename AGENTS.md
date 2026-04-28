# MASM32 SDK Project Instructions

This repository contains a Win32 Assembly application written using the MASM32 SDK. 

## Architecture & Environment
- **Language**: MASM32 Assembly (`.asm`).
- **Dependencies**: Relies on the MASM32 standard library (`\masm32\include\masm32rt.inc`).
- **Execution Environment**: Designed for Windows (Win32 API). If working on Linux, compilation requires `wine` with the MASM32 SDK installed, or it must be cross-compiled.

## Compilation Commands
There is no automated build script present. To compile manually using the MASM32 toolchain (assuming `ml.exe` and `link.exe` are in your PATH or running via Wine):

```cmd
:: Assemble
ml /c /coff /Cp crud_estudiantes.asm

:: Link (Console subsystem)
link /SUBSYSTEM:CONSOLE /LIBPATH:\masm32\lib crud_estudiantes.obj
```

## Data Storage Quirks
- The app operates on binary data directly (`alumnos.dat`).
- Structs (e.g., `Alumno`) are strictly mapped to binary files via MASM32 macros (`fopen`, `fread`, `fwrite`, `fcreate`, `fdelete`) and Win32 API (`MoveFile`). Ensure struct byte alignment is taken into account when modifying schemas.
- Deletion operates via a temporary file filter, rather than a logical flag.