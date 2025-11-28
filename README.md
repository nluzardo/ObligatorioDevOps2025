#  Obligatorio Programación DevOps — Gestión de Usuarios en Linux Introducción

El área de Infraestructura recibió la tarea de desarrollar un mecanismo automatizado para la creación controlada de usuarios en un sistema Linux, asegurando validaciones estrictas, registros adecuados, manejo de errores y comportamiento personalizable mediante modificadores.
Con este objetivo se desarrolla un script en Bash capaz de crear usuarios basándose en un archivo de entrada estructurado, permitiendo además asignar contraseñas, gestionar la creación del home, y brindar retroalimentación detallada mediante la opción verbose.

##  Ejercicio 1 - Script Bash – Creación Masiva de Usuarios en Linux

###  Introducción
Este script permite **crear usuarios en masa** a partir de un archivo de texto con un formato específico.  
Incluye controles de validación, manejo de errores, reporte opcional por usuario y la posibilidad de asignar una contraseña común a todos los usuarios creados.

---

##  Descripción del Script
El script procesa un archivo que contiene, línea por línea, la definición de usuarios con 5 campos separados por `:`.

Ejemplo:

usuario1:Comentario:/home/usuario1:SI:/bin/bash

El script:
- Valida correctitud del formato del archivo.
- Chequea usuarios duplicados.
- Verifica nombres de usuario válidos.
- Crea o no el home según corresponda.
- Asigna shell, comentario y contraseña opcional.
- Muestra información detallada si se usa '-i'.

---

##  Sintaxis

./crear_usuarios.sh [-i] [-c "contraseña"] archivo_usuarios

###  Parámetros
| Parámetro | Descripción |
|-----------|-------------|
| '-i'               | Muestra información detallada por cada usuario creado |
| '-c "contraseña"'  | Contraseña común para todos los usuarios (sin espacios) |
| 'archivo_usuarios' | Archivo con los usuarios (obligatorio) |

Ejemplo:

./crear_usuarios.sh -i -c "MiPass123" usuarios.txt

---

##  Formato del archivo de entrada
Cada línea debe contener **5 campos** separados por ':':

USUARIO:COMENTARIO:RUTA_HOME:CREARHOME:SHELL

Ejemplo:

juanperez:Usuario de Marketing:/home/juanperez:SI:/bin/bash

---

##  Validaciones del Script
El script controla:
- Cantidad correcta de parámetros.
- Contraseñas sin espacios.
- Archivo existente, regular y con permisos de lectura.
- Formato con exactamente 5 campos.
- Usuarios duplicados.
- Nombres de usuario válidos.
- Home absoluto cuando corresponde.

Códigos de error:

| Código | Significado |
|--------|-------------|
| 1 | Uso incorrecto |
| 2 | No se especificó archivo |
| 3 | Archivo inexistente o no regular |
| 4 | Sin permisos de lectura |
| 5 | Formato incorrecto |
| 6 | Error al crear usuario |
| 7 | Usuario duplicado |
| 8 | Nombre inválido |

---

##  Contraseñas
Si se utiliza '-c':
- Todos los usuarios reciben la misma contraseña.
- No se permiten espacios.
- Si no se especifica contraseña, se informa y se crean sin ella.

---

##  Salida del Script

###  Modo normal
- Muestra errores y advertencias.
- Indica cuántos usuarios fueron creados.

###  Modo informativo ('-i')
Muestra:
- Usuario creado
- Comentario
- Shell
- Home
- Decisiones tomadas por el script

---

##  Requisitos
- Linux con 'useradd'.
- Permisos de superusuario.
- Archivo con formato válido.

---

##  README — Ejercicio 2: Infraestructura Automatizada en AWS

Descripción: Este proyecto automatiza la creación de una infraestructura básica en AWS para desplegar una aplicación web con base de datos. Utiliza Python y boto3 para crear los recursos necesarios, incluyendo EC2, RDS, S3, grupos de seguridad y claves SSH. El despliegue se adapta a una aplicación PHP/Apache clonada desde GitHub.

##  Requisitos:

Cuenta activa en AWS (lab o personal)

Python 3.12 o superior

AWS CLI configurado

Acceso a credenciales temporales (Access Key, Secret Key, Session Token)

Sistema Linux con soporte para Bash o Fish

Instalación:

Clonar el repositorio: git clone https://github.com/nluzardo/App_Obligatorio.git cd Ejercicio2

Crear y activar entorno virtual:

Para Bash: python3 -m venv venv source venv/bin/activate

Para Fish: source venv/bin/activate.fish

Instalar dependencias: pip install boto3 python-dotenv 

Configuración del entorno:

Crear archivo .env basado en env.example: cp env.example .env

Completar con credenciales y parámetros válidos:

##  Código

AWS_ACCESS_KEY_ID=TU_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=TU_SECRET_KEY
AWS_SESSION_TOKEN=TU_SESSION_TOKEN
AWS_REGION=us-east-1

KEY_NAME=Key_Salbanese
AWS_IMAGE_ID=ami-0fa3fe0fa7920f68e
AWS_INSTANCE_TYPE=t2.micro
AWS_S3_NAME=Obligatorio_Salbanese
DB_IDENTIFIER=una-bd2
DB_INSTANCE_CLASS=db.t3.micro
DB_ENGINE=mariadb
DB_MASTER_USER_NAME=admin
DB_MASTER_PASSWORD=Admin123!

##  Ejecución:

Ejecutar el script principal: python crear_infra.py

El script realiza:

Creación de par de claves

Creación de grupos de seguridad con reglas para SSH, HTTP y DB

Creación de bucket S3

Subida de archivo de prueba

Creación de instancia EC2 con user_data_socios.sh

Creación de instancia RDS

## Verificar acceso web: 

Abrir navegador en: http://<IP pública de la EC2>
