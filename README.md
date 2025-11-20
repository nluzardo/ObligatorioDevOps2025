Obligatorio Programación DevOps — Gestión de Usuarios en Linux
Introducción

El área de Infraestructura recibió la tarea de desarrollar un mecanismo automatizado para la creación controlada de usuarios en un sistema Linux, asegurando validaciones estrictas, registros adecuados, manejo de errores y comportamiento personalizable mediante modificadores.

Con este objetivo se desarrolla un script en Bash capaz de crear usuarios basándose en un archivo de entrada estructurado, permitiendo además asignar contraseñas, gestionar la creación del home, y brindar retroalimentación detallada mediante la opción verbose.

Script en Bash — crear_usuarios.sh
Consigna

Desarrollar un script en Bash que:

Lea un archivo con usuarios y sus atributos separados por “:”.

Valide:

Formato correcto de la línea (5 campos).

Nombre de usuario válido.

Campos no vacíos donde corresponda.

Que el usuario no exista previamente.

Indicaciones sobre creación del HOME (SI / NO / inválido).

Permita:

Crear usuarios en el sistema.

Crear o no el directorio home según el archivo.

Asignar una contraseña común mediante -c.

Obtener información detallada por usuario mediante -i.

Prerrequisitos

El archivo crear_usuarios.sh debe tener permisos de ejecución.

chmod +x crear_usuarios.sh


Sintaxis:

./crear_usuarios.sh [-i] [-c contraseña] archivo_usuarios.txt


El archivo de entrada debe tener 5 campos separados por “:”:

usuario:comentario:home:SI|NO:shell

Solución implementada

El script realiza los siguientes pasos:

1. Validación de parámetros

Verifica cantidad de parámetros.

Controla modificadores válidos:

-i → modo informativo.

-c → asignar contraseña común.

Si la contraseña contiene espacios, se aborta la ejecución.

Verifica existencia y permisos del archivo de usuarios.

2. Lectura y procesamiento del archivo

Para cada línea:

Se eliminan espacios sobrantes con xargs.

Se ignoran líneas vacías o comentarios.

Se confirma que existan 5 campos.

Se valida el nombre del usuario con regex Linux:

^[a-z_][a-z0-9_-]*$


Se verifica si el usuario existe en el sistema.

3. Validaciones específicas

Si CREARHOME = SI:

Se valida si el HOME es una ruta absoluta.

Si no lo es, se reemplaza por /home/usuario.

Usa useradd -m.

Si CREARHOME = NO o valor inválido:

Usa useradd -M.

No crea directorio HOME, aunque se muestre en /etc/passwd.

4. Creación del usuario en el sistema

Se aplica:

Comentario (-c)

Home (-d)

Shell (-s)

Creación o no del HOME (-m / -M)

Si se asignó contraseña, se aplica mediante chpasswd.

5. Modo informativo (-i)

Si se activa:

Se muestra un resumen detallado de:

Usuario creado

Comentario

Directorio HOME (o aclaración si NO se creó)

Tipo de creación

Shell configurado

6. Manejo de errores

Se gestionan errores específicos:

Código	Motivo
1	Uso incorrecto
2	Falta archivo
5	Formato incorrecto
7	Usuario duplicado
8	Nombre de usuario inválido
6	Error al crear usuario
7. Resumen final

Al finalizar, muestra cuántos usuarios se crearon exitosamente.

Ejemplo de archivo de entrada
pepe:usuario estandar:/home/pepe:SI:/bin/bash
maria:sin home:/home/maria:NO:/bin/bash
otrousuario:comentario extra:/home/otro:SI:/bin/bash

Ejemplo de ejecución
Modo normal
./crear_usuarios.sh archivo_usuarios.txt

Modo informativo
./crear_usuarios.sh -i archivo_usuarios.txt

Con contraseña común
./crear_usuarios.sh -i -c "Pass123" archivo_usuarios.txt

Resultado esperado

Usuarios creados correctamente según archivo.

Validaciones aplicadas.

Home creado o no según especificación.

Log de errores directo en consola.

Control estricto de formato y seguridad.
