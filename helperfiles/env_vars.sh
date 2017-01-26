#!/bin/bash

# AUTHOR      : Manoj Talwar
# EMAIL       : talwarmanoj@gmail.com
# DESCRIPTION : Environment variable for grails-petclinic

export SSH_AUTH_SOCK=0
export LOCAL_WAR_FILE=${HOME}/grails-petclinic/target/petclinic-0.2.war
export PRIVATE_KEY_FILE=${HOME}/.ssh/id_petclinic
export REMOTE_HOME_DIR=/home/devops
export REMOTE_DEVOPS=${REMOTE_HOME_DIR}/.devops
export REMOTE_TOMCAT_DIR=/var/lib/tomcat7
export REMOTE_WAR_FILE=${REMOTE_TOMCAT_DIR}/webapps/ROOT.war
export BACKUP_WAR_FILE=${REMOTE_HOME_DIR}/petclinic.war.backup
export TMP_UPLOAD_LOCATION=/tmp/petclinic.war
