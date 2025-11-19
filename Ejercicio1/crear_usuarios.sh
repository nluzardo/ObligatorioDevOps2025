#!/bin/bash

#Estructuras de control

INFO=0 #Indica por defecto que no mostremos informacion
PASSWORD="" #Password por defecto, vacia
ARCHIVO="" #archivo por defecto, vacio 
CREADOS=0             # contador de usuarios creados exitosamente
LINEA_NUM=0           # número de línea actual (para mensajes de error)
ERROR_FLAG=0          # si queda en 0 -> todo ok; distinto -> hubo errores


#Errores posibles del programa

E_USAGE=1             # error de uso / parámetros
E_NOFILE=2            # no se especificó archivo
E_NOTREG=3            # archivo no es regular o no existe
E_NOREAD=4            # no hay permisos de lectura sobre el archivo
E_BADFORMAT=5         # línea con formato incorrecto (número de campos distinto de 5)
E_USERADD=6           # fallo al crear un usuario (useradd/chpasswd)
E_USERDUP=7           # usuario duplicado
E_BADUSER=8         # Nombre de usuario no valido

#Funcion para mostrar el uso

mostrar_uso() {
    # Muestra ayuda por STDERR y devuelve código de uso
    cat >&2 <<EOF
Uso: $0 [-i] [-c contraseña] Archivo_con_los_usuarios
  -i                Informar resultado por cada usuario
  -c "contraseña"   Asignar esta contraseña a todos los usuarios creados
Ejemplo:
  $0 -i -c "123456" Usuarios
EOF
    exit $E_USAGE  #Error de Uso incorrecto del programa
}

#Chequeamos que la cantidad de parametros sea la correcta
if [ $# -lt 1 ] || [ $# -gt 4 ]; then
    echo "Error: cantidad incorrecta de parámetros."
    mostrar_uso
fi

#Chequeamos que los parametros esten en orden correcto

# Si la cantidad de parámetros es inválida
if [ $# -lt 1 ] || [ $# -gt 4 ]; then
    echo "Error: cantidad incorrecta de parámetros."
    mostrar_uso
fi

# Procesamiento de parámetros permitidos: -i y -c
while [ $# -gt 0 ]; do
    case "$1" in
        -i)
            INFO=1   # Activar modo información
            shift    # Pasar al siguiente parámetro
            ;;
        -c)
            # Opción de contraseña, requiere argumento
            if [ -z "$2" ]; then
                echo "Error: la opción -c requiere una contraseña." >&2
                mostrar_uso
                exit $E_USAGE
            fi
            PASSWORD="$2"   # Guardamos contraseña
            shift 2         # Avanzamos dos posiciones
            ;;
        -*)
            # Cualquier otro modificador es inválido (-I, -C, etc)
            echo "Error: parámetro inválido '$1'." >&2
            mostrar_uso
            exit $E_USAGE
            ;;
        *)
            # Primer parámetro que no es opción → es el archivo
            ARCHIVO="$1"
            shift # Mueve todo un parámetro hacia la izquierda
            ;;
    esac
done

# Validación: debe haberse recibido un archivo
if [ -z "$ARCHIVO" ]; then
    echo "Error: no se especificó archivo." >&2
    mostrar_uso
    exit $E_NOFILE
fi
#Chequeamos si se epecifico o no una contraseña y avisamos al usuario
if [ -z "$PASSWORD" ]; then
    echo "No se especificó una contraseña. Los usuarios se crearán sin contraseña."
else
    echo "Se utilizará la contraseña especificada: '$PASSWORD'"
fi

#Aca validamos que el archivo exista
if [ ! -f "$ARCHIVO" ]; then
    echo "Error: el archivo no existe, no es regular o no se agrego a los parametros."
    mostrar_uso
    exit 4
fi

#Validacion de permisos sobre el archivo
if [ ! -r "$ARCHIVO" ]; then
    echo "Error: no hay permisos de lectura sobre '$ARCHIVO'."
    mostrar_uso
    exit 5
fi

echo "Creando usuarios"
while IFS=":" read -r USUARIO COMENTARIO HOME CREARHOME SHELL #Leemos una linea a la vez del archivo y se pasa por bucle
do
    LINEA_NUM=$((LINEA_NUM + 1))

    # Ignorar líneas vacías o comentarios
    [ -z "$USUARIO" ] && continue
    [[ "$USUARIO" =~ ^# ]] && continue

    # Verificar que tenga exactamente 5 campos
    CAMPOS=$(echo "$USUARIO:$COMENTARIO:$HOME:$CREARHOME:$SHELL" | awk -F: '{print NF}')
    if [ "$CAMPOS" -ne 5 ]; then
        echo "Error en línea $LINEA_NUM: formato incorrecto (se esperaban 5 campos)." >&2
        ERROR_FLAG=$E_BADFORMAT
        echo "listo"
	continue
    fi
 # Si el comentario está vacío
    [ -z "$COMENTARIO" ] && COMENTARIO="Sin comentario"

    # Si el home está vacío
    [ -z "$HOME" ] && HOME="/home/$USUARIO"

    # Si el shell está vacío
    [ -z "$SHELL" ] && SHELL="/bin/bash"

 # Determinar si se crea el home
    if [ "$CREARHOME" = "SI" ]; then
        OPCION_HOME="-m"
    else
        OPCION_HOME=""
    fi
 # Crear el usuario
    if id "$USUARIO" &>/dev/null; then # Corroborar que el usuario ya exista o no
    if [ $INFO -eq 1 ]; then
        echo "El usuario $USUARIO ya existe. No se creará nuevamente."
        ERROR_FLAG=$E_USERDUP
    fi
    continue
    fi

    # Chequear que el usuario no tenga caracteres no comprendidos o espacios
    if ! [[ "$USUARIO" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Error línea $LINEA_NUM: nombre de usuario inválido '$USUARIO'." >&2
    ERROR_FLAG=$E_BADUSER
    fi

    useradd $OPCION_HOME -d "$HOME" -s "$SHELL" -c "$COMENTARIO" "$USUARIO" 2>/dev/null
    RESULTADO=$?

    if [ $RESULTADO -eq 0 ]; then
        # Si hay contraseña definida
        if [ -n "$PASSWORD" ]; then
            echo "$USUARIO:$PASSWORD" | chpasswd 2>/dev/null
        fi
        CREADOS=$((CREADOS + 1))
        if [ $INFO -eq 1 ]; then
            echo ""
	    echo "Usuario $USUARIO creado con éxito con datos:"
            echo "  Comentario: $COMENTARIO"
            echo "  Dir home: $HOME"
            echo "  Asegurado existencia de directorio home: $CREARHOME"
            echo "  Shell: $SHELL"
            echo ""
        fi
    else
        echo "ATENCIÓN: el usuario $USUARIO no pudo ser creado." >&2
        ERROR_FLAG=$E_USERADD
    fi

done < "$ARCHIVO"

echo ""
echo "Se han creado $CREADOS usuarios con éxito."

exit $ERROR_FLAG
