import boto3
import os
from botocore.exceptions import ClientError

# Crear cliente EC2
ec2 = boto3.client('ec2')

# Crear el par de claves
key_name = 'clave-profe-unica-007'
key_pair = ec2.create_key_pair(KeyName=key_name)
with open(f'{key_name}.pem', 'w') as file:
    file.write(key_pair['KeyMaterial'])
os.chmod(f'{key_name}.pem', 0o400)
print(f"Par de claves creado y guardado como {key_name}.pem")

# Crear grupos de seguridad
sg_ec2_name = "SG-De-mi-ec2"
response = ec2.create_security_group(GroupName=sg_ec2_name, Description="Grupo de seguridad para mi ec2")
sg_ec2_id = response['GroupId']
print(f"Grupo de seguridad creado con el id: {sg_ec2_id}")

sg_db_name = "SG_base_datos"
response = ec2.create_security_group(GroupName=sg_db_name, Description="Grupo de seguridad para la base de datos")
sg_db_id = response['GroupId']
print(f"Grupo de seguridad creado con el id: {sg_db_id}")

# Reglas de ingreso
ec2.authorize_security_group_ingress(GroupId=sg_ec2_id,
                                     IpPermissions=[{
                                        'IpProtocol': 'tcp',
                                        'FromPort': 22,
                                        'ToPort': 22,
                                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]}])

ec2.authorize_security_group_ingress(GroupId=sg_ec2_id,
                                     IpPermissions=[{
                                        'IpProtocol': 'tcp',
                                        'FromPort': 80,
                                        'ToPort': 80,
                                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]}])

ec2.authorize_security_group_ingress(GroupId=sg_db_id,
                                     IpPermissions=[{
                                        'IpProtocol': 'tcp',
                                        'FromPort': 3306,
                                        'ToPort': 3306,
                                        'UserIdGroupPairs': [{'GroupId': sg_ec2_id}]}])

# Cliente RDS
rds = boto3.client("rds")

db_identifier = "Mi-db-obligatorio"
DB_INSTANCE_CLASS = "db.t3.micro"
ENGINE = "mariadb"
USER_NAME = "admin"
DB_PASSWORD = "admin1234"

# Crear instancia RDS con manejo de error
try:
    response = rds.create_db_instance(
                   DBInstanceIdentifier=db_identifier,
                   AllocatedStorage=20,
                   DBInstanceClass=DB_INSTANCE_CLASS,
                   Engine=ENGINE,
                   MasterUsername=USER_NAME,
                   MasterUserPassword=DB_PASSWORD,
                   VpcSecurityGroupIds=[sg_db_id]
        )
    print("Instancia RDS creada")
    print("Esperando que quede disponible ...")
    waiter = rds.get_waiter('db_instance_available')
    waiter.wait(DBInstanceIdentifier=db_identifier)
    print("Ahora la DB ya está pronta")
except ClientError as e:
    if e.response['Error']['Code'] == 'DBInstanceAlreadyExists':
        print(f"La instancia RDS '{db_identifier}' ya existe, continuando sin crearla de nuevo.")
    else:
        raise

# Crear instancia EC2
ec2_resource = boto3.resource('ec2')

AWS_IMAGE_ID = "ami-0157af9aea2eef346"
AWS_INSTANCE_TYPE = "t2.micro"
KEY_NAME = key_name
AWS_EC2_NAME = "mi-ec2"

instances = ec2_resource.create_instances(
    ImageId=AWS_IMAGE_ID,
    MinCount=1,
    MaxCount=1,
    InstanceType=AWS_INSTANCE_TYPE, 
    KeyName=KEY_NAME,
    SecurityGroupIds=[sg_ec2_id],
    TagSpecifications=[
        {
            'ResourceType': 'instance',
            'Tags': [{'Key': 'Name', 'Value': AWS_EC2_NAME}]
        }
    ]
)

print("Instancia EC2 creada con ID:", instances[0].id)

