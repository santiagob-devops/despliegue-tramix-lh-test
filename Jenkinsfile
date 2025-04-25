//Variables por ambiente
def SERVER_HOST = "10.0.44.80"
def SERVER_NAME = "test"
def SERVER_USERNAME = "unitech"
def SERVER_FOLDER = "conicet/composes" 
def APP_URL = "http://tramix-cnative-ubu.silver.conicet.gov.ar/tramix-lh-ui/"
//def TOKENCHAT = "https://chat.googleapis.com/v1/spaces/AAAA3-tMX1o/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=-dH-Hw2VFyim8Rlu1T9UToTuPei4xzddyTmokml4PTo%3D"
def SERVER_FOLDER_VERSION = "/opt/unitech/conicet/apis/tramix-lh-api/version"

//Variables comunes
def PATH_OUTPUT = "/var/scripts"
def COMMAND_LOAD = "docker load -i /opt/unitech/cd/scripts"
def paramsOk = false;
def descargaUiOk = false;
def descargaAPIOk = false;

def existeArtefacto(String artifact){
    status = sh ( script: "ls -la ${artifact}", returnStatus: true)
    return (status == 0)
}

pipeline {

    agent any

	environment {
		FTP_USER = credentials("ftp-unitech")
    }

     parameters {
        choice(name: 'COMPONENT', choices: ['tramix-lh'], description: "Seleccione el componente a desplegar en el ambiente ${SERVER_NAME}:")
        string(name: "VERSION", defaultValue: "0", description: "Número de versión a desplegar")
        string(name: "PRODUCT_VERSION", defaultValue: "0.0", description: "Versión del producto")
    }

    stages {

        stage ("Iniciar") {
            steps {
                script {    

                    echo 'Validación de parámetros de entrada '

                    if ("${params.VERSION}" == "0" ) {
                        currentBuild.result = 'FAILURE'
                        throw new Exception("El campo VERSION es obligatorio. Vuelva a ejecutar la tarea informando todos los campos")
                    }
                    if ("${params.PRODUCT_VERSION}" == "0.0" ) {
                        currentBuild.result = 'FAILURE'
                        throw new Exception("El campo PRODUCT_VERSION es obligatorio. Vuelva a ejecutar la tarea informando todos los campos")
                    }                          
                    paramsOk = true;

                    echo 'Asignación de variables'

                    env.MS_NAME = "${params.COMPONENT}"
                    env.DOCKER_NAME = "${SERVER_NAME}-${env.MS_NAME}"
                    //env.INFO_LINK = "${APP_URL}${env.MS_NAME}-${env.API}/info"
                    env.PATH_SERVER_UI = "/opt/unitech/${SERVER_FOLDER}/${env.MS_NAME}-ui"
                    env.PATH_SERVER_API = "/opt/unitech/${SERVER_FOLDER}/${env.MS_NAME}-api"
                    env.FILE = "docker-compose.yml"
                    env.COMMAND_DOWN = "docker-compose -f ${env.PATH_SERVER}/${env.FILE} down -v --rmi all"
                    env.COMMAND_UP = "docker-compose -f ${env.PATH_SERVER}/${env.FILE} up -d"
                }
            }
        }

        stage("Actualizar versión en .env") {
            steps {
                script {
                    echo "Ejecutando script remoto para actualizar la versión..."

                    // Ejecuta el script por SSH usando los parámetros del pipeline
                    sh """
                        ssh -o StrictHostKeyChecking=no ${SERVER_USERNAME}@${SERVER_HOST} \\
                        "${env.PATH_SERVER_UI}/actualizar_version.sh ${params.VERSION}"
                    """
                    sh """
                        ssh -o StrictHostKeyChecking=no${SERVER_USERNAME}@${SERVER_HOST} \\
                        "${env.PATH_SERVER_API}/actualizar_version.sh ${params.VERSION}"
                    """
                }
            }
        }

        stage("Reiniciar servicios con docker-compose") {
            steps {
                script {
                    echo "Deteniendo contenedores existentes..."

                    sh "ssh -o StrictHostKeyChecking=no${SERVER_USERNAME}@${SERVER_HOST} docker-compose -f ${env.PATH_SERVER_UI}/docker-compose.yml down -v --rmi all || true"
                    sh "ssh -o StrictHostKeyChecking=no${SERVER_USERNAME}@${SERVER_HOST} docker-compose -f ${env.PATH_SERVER_API}/docker-compose.yml down -v --rmi all || true"

                    echo "Iniciando contenedores con nueva versión..."

                    sh "ssh -o StrictHostKeyChecking=no${SERVER_USERNAME}@${SERVER_HOST} docker-compose -f ${env.PATH_SERVER_UI}/docker-compose.yml up -d"
                    sh "ssh -o StrictHostKeyChecking=no${SERVER_USERNAME}@${SERVER_HOST} docker-compose -f ${env.PATH_SERVER_API}/docker-compose.yml up -d"
                }
            }
        }

        stage("Verificar que los contenedores estén corriendo") {
            steps {
                script {
                    echo "Esperando 10 segundos antes de verificar los contenedores..."
                    sleep(time: 10, unit: "SECONDS")

                    def checkUI = sh(script: "ssh ${SERVER_USERNAME}@${SERVER_HOST} docker ps | grep tramix-lh-ui", returnStatus: true)
                    def checkAPI = sh(script: "ssh ${SERVER_USERNAME}@${SERVER_HOST} docker ps | grep tramix-lh-api", returnStatus: true)
                    
                    if (checkUI != 0 || checkAPI != 0) {
                        currentBuild.result = 'FAILURE'
                        error("Uno o más contenedores no están corriendo correctamente.")
                    }

                    echo "Todos los contenedores están activos y corriendo correctamente."
                }
            }
        }

        stage("Fin de ejecución") {
            steps {
                echo "Despliegue completado exitosamente para la versión ${params.VERSION} del componente ${params.COMPONENT}"
            }
        }
                   
    }
}
