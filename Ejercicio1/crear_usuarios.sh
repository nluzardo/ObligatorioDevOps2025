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
    exit $E_USAGE  #Error de Uso incorrecto
}

#Chequeamos que la cantidad de parametros sea la correcta
if [ $# -lt 1 ] || [ $# -gt 4 ]; then
    echo "Error: cantidad incorrecta de parámetros."
    mostrar_uso
fi

#Chequeamos que los parametros esten en orden correcto
if [ "$1" = "-i" ]; then
    INFO=1
    if [ "$2" = "-C" ]; then
        PASSWORD="$3"
        ARCHIVO="$4"
    elif [ "$2" = "-c" ];then #Solo admitimos el parametro -C
        echo "Error, -c no es un parametro aceptado." 
        mostrar_uso
        exit 2
    else
        ARCHIVO="$2"
    fi
elif [ "$1" = "-I" ]; then #Solo admitimos el parametro como -i
    echo "Error, -I no es un parametro aceptado."
    mostrar_uso
    exit 3
elif [ "$1" = "-C" ]; then
    PASSWORD="$2"
    ARCHIVO="$3"
else
    ARCHIVO="$1"
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
echo "listo"
