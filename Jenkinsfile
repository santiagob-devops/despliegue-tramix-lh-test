//Variables por ambiente
def SERVER_HOST = "10.0.44.80"
def SERVER_NAME = "test"
def SERVER_USERNAME = "unitech"
def SERVER_FOLDER = "testing" 
def APP_URL = "http://tramix-cnative-ubu.silver.conicet.gov.ar/tramix-lh-ui/"
def TOKENCHAT = "https://chat.googleapis.com/v1/spaces/AAAA3-tMX1o/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=-dH-Hw2VFyim8Rlu1T9UToTuPei4xzddyTmokml4PTo%3D"
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
        choice(name: 'COMPONENT', choices: ['tramix'], description: "Seleccione el componente a desplegar en el ambiente ${SERVER_NAME}:")
        string(name: "VERSION", defaultValue: "0", description: "Número de versión a desplegar")
        string(name: "BUILD_ID", defaultValue: "0", description: "Número de build a desplegar (corresponde al número que se coloca luego de .build-)")
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

                    if ("${params.BUILD_ID}" == "0") {
                        currentBuild.result = 'FAILURE'
                        throw new Exception("El campo BUILD_ID es obligatorio. Vuelva a ejecutar la tarea informando todos los campos")
                    }

                    if ("${params.PRODUCT_VERSION}" == "0.0") {
                        currentBuild.result = 'FAILURE'
                        throw new Exception("El campo PRODUCT_VERSION es obligatorio. Vuelva a ejecutar la tarea informando todos los campos")
                    }  

                    paramsOk = true;

                    echo 'Asignación de variables'

                    env.MS_NAME = "${params.COMPONENT}"
                    env.DOCKER_NAME = "gpsl-${env.MS_NAME}"
                    env.UI = 'ui'
                    env.API = 'ui-api'
                    env.INFO_LINK = "${APP_URL}${env.MS_NAME}-${env.API}/info"
                    env.PATH_SERVER = "/opt/unitech/${SERVER_FOLDER}/${env.MS_NAME}"
                    env.PATH_FTP = "GPSL01/gpsl/tramix-container"
                    env.FILE = "docker-compose-${env.MS_NAME}.yml"
                    env.COMMAND_DOWN = "docker-compose -f ${env.PATH_SERVER}/${env.FILE} down -v --rmi all"
                    env.COMMAND_UP = "docker-compose -f ${env.PATH_SERVER}/${env.FILE} up -d"
                }
            }
        }

        stage ("Descargar") {
            when {
                expression { paramsOk }
            }
            steps {
                script {

                    echo 'Descarga de nueva version de componente del ftp'
                    sh label: "Descarga UI", script: "curl -v -u ${FTP_USER_USR}:${FTP_USER_PSW} ftp://ftp.unitech.com.ar/${PATH_FTP}/${env.MS_NAME}-${params.VERSION}-build.${params.BUILD_ID}/${env.MS_NAME}-${env.UI}.tar.gz --output ${PATH_OUTPUT}/${env.MS_NAME}-${env.UI}.tar.gz"                                   
                    sh label: "Descarga API", script: "curl -v -u ${FTP_USER_USR}:${FTP_USER_PSW} ftp://ftp.unitech.com.ar/${PATH_FTP}/${env.MS_NAME}-${params.VERSION}-build.${params.BUILD_ID}/${env.MS_NAME}-${env.API}.tar.gz --output ${PATH_OUTPUT}/${env.MS_NAME}-${env.API}.tar.gz"

                    descargaUiOk = existeArtefacto("${PATH_OUTPUT}/${env.MS_NAME}-${env.UI}.tar.gz")
                    descargaApiOk = existeArtefacto("${PATH_OUTPUT}/${env.MS_NAME}-${env.API}.tar.gz")
                }                
            }
        }

        stage("Subir") {
            when {
                expression { descargaApiOk }
            }            
            steps {
                script {
                    echo 'Subida de imagen docker'
                    sh label: "Subida UI", script: "ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | ${COMMAND_LOAD}/${env.MS_NAME}-${env.UI}.tar.gz '"
                    sh label: "Subida API", script: "ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | ${COMMAND_LOAD}/${env.MS_NAME}-${env.API}.tar.gz '"
                }
            }
        }           

        stage("Detener y eliminar") {
            when {
                expression { descargaApiOk }
            }                  
            steps {
                script {

                    echo 'Detención y eliminación de docker'
                    try {
                        sh label: "Eliminacion UI", script:"ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | docker rm -f ${env.DOCKER_NAME}-${env.UI}'"
                        sh label: "Eliminacion API", script:"ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | docker rm -f ${env.DOCKER_NAME}-${env.API}'"
                    }
                    catch (err) {
                        echo "Se produjo un error al eliminar el docker. Se continúa con la ejecución."
                    }          
                }
            }
        }           

        stage("Versionar") {
            when {
                expression { descargaApiOk }
            }                
            steps {
                script {
                    echo 'Actualización de versión en docker-compose'
                    sh label: "Versionado", script:"ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | ${env.PATH_SERVER}/reemplazarversion.sh ${params.VERSION}'"
                }
            }
        }

         stage("Versionar producto") {
            when {
                expression { descargaApiOk }
            }        
            steps{
                script{
                    echo "Set Global Product Version"
                    sh "ssh -o StrictHostKeyChecking=no ${SERVER_USERNAME}@${SERVER_HOST} 'cd ${SERVER_FOLDER_VERSION} && ./versionar.sh ${params.PRODUCT_VERSION}'"
                }
                
            }
        }

        stage("Desplegar") {
            when {
                expression { descargaApiOk }
            }
            steps {
                script {
                    echo 'Despliegue de docker'
                    sh label: "Inicio", script:"ssh ${SERVER_USERNAME}@${SERVER_HOST} 'yes | ${env.COMMAND_UP}'"          
                }
            }
        }

        stage("Avisar entrega") {
            when {
                expression { descargaApiOk }
            }
            steps {
                script {
                     googlechatnotification url: "${TOKENCHAT}", message: "Se desplego *${env.MS_NAME} ${env.VERSION}* en el ambiente de *${SERVER_NAME}*. Puede verificarla desde ${INFO_LINK}"                    
                }
            }
        }            

        stage("Limpiar") {
            when {
                expression { descargaApiOk }
            }               
            steps {
                script {
                    echo "Eliminación de archivos tar.gz utilizados para liberar espacio en el servidor"
                    try {
                        if (existeArtefacto("${PATH_OUTPUT}/${env.MS_NAME}-${env.UI}.tar.gz")) {
                            sh label: "Eliminacion de UI", script: "rm ${PATH_OUTPUT}/${env.MS_NAME}-${env.UI}.tar.gz"
                        }      
                        if (existeArtefacto("${PATH_OUTPUT}/${env.MS_NAME}-${env.API}.tar.gz")) {
                            sh label: "Eliminacion de API", script: "rm ${PATH_OUTPUT}/${env.MS_NAME}-${env.API}.tar.gz"
                        }                                               
                    } catch (err) {
		                echo "Se produjo un error al eliminar el o los archivos. Esto no es un error bloqueante para el despliegue."
        		    } 
   		        }
            }
        }             
    }
}
