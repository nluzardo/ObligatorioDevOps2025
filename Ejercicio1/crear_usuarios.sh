#!/bin/bash

#Estructuras de control

INFO=0 #Indica por defecto que no mostremos informacion
PASSWORD="" #Password por defecto, vacia
ARCHIVO="" #archivo por defecto, vacio 

#Funcion para mostrar el uso
mostrar_uso() {
    echo "Uso: $0 [-i] [-C contraseña] archivo_usuarios.txt"
    echo "Ejemplo:"
    echo "  $0 -i -C 1234 usuarios.txt"
    exit 1
}

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
    else
        ARCHIVO="$2"
    fi
elif [ "$1" = "-C" ]; then
    PASSWORD="$2"
    ARCHIVO="$3"
else
    ARCHIVO="$1"
fi
