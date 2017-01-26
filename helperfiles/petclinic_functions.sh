#!/bin/bash

# AUTHOR      : Manoj Talwar
# EMAIL       : talwarmanoj@gmail.com
# DESCRIPTION : Functions for deploying and rolling back grails-petclinic war file to tomcat

# Currently echo-ing log messages on console
WRITE_LOG=echo

# Do the tidy up at the beginning
function start_with_clean_slate()
{
    cd $HOME
    rm -rf ./grails-petclic
}

# Pre-requisite: check whether sshpass is installed
function check_for_sshpass_package()
{
     if [ -e /usr/bin/sshpass ]; then
         $WRITE_LOG "INFO: sshpass is installed on this system"
     else
         $WRITE_LOG "ERROR: sshpass package is not installed. Please install it and then run this script again"
         exit -1
     fi
}

# Use existing key pair if present from previous run or else:
#    a) Generate a new rsa key pair
#    b) Request your sysadmin to enter the password of 'devops' user to do a one-off setup
#    c) Copy public key to the server
function deal_with_ssh_keypair() 
{
    if [ -e "$PRIVATE_KEY_FILE" ]; then
        $WRITE_LOG "INFO: Using the already configured key pair to connect to server"
    else
        $WRITE_LOG "INFO: Creating a new rsa key pair"
        ssh-keygen -t rsa -P "" -f $PRIVATE_KEY_FILE
        if [ $? -ne 0 ]; then
            $WRITE_LOG "ERROR: Problem with ssh-keygen. Please ensure that ssh-keygen is installed and working"
            exit -1
        fi
        echo "Ask your System Administrator to enter the password of 'devops' user for one off-setup ::::: "
        read -s DEVOPS
        sshpass -p $DEVOPS ssh devops@ubuntu "echo $DEVOPS > $REMOTE_DEVOPS" 
        if [ $? -ne 0 ]; then
            $WRITE_LOG "ERROR: Please ensure that you have sshpass package installed on your system"
        fi
        $WRITE_LOG "INFO: Copying the public key to the server"
        sshpass -p $DEVOPS ssh-copy-id devops@ubuntu
        if [ $? -ne 0 ]; then
            $WRITE_LOG "ERROR: Problem copying public key to server. Please ensure sshpass is installed and working"
            rm -f $HOME/.ssh/id_petclinic*
            exit -1
        fi
    fi
}

# Clone repo from github
function clone_repo_from_github()
{
    $WRITE_LOG "INFO: Cloning the grails-petclinic repo from github"
    git clone https://github.com/secretescapes/grails-petclinic.git
    if [ $? -ne 0 ]; then
        $WRITE_LOG "ERROR: Could not clone grails-petclinic repo from github"
        exit -1
    fi
}

# If clone was successful generate the new war file
function generate_new_war_file()
{
    $WRITE_LOG "INFO: Generating the new war file"
    cd ${HOME}/grails-petclinic
    #./grailsw war
    if [ $? -ne 0 ]; then
       $WRITE_LOG "ERROR: Could not clone grails-petclinic repo"
       exit -1
    fi
}

# If war file got created then upload it to tmp directory on the server
function upload_war_tmp_location()
{
    $WRITE_LOG "INFO: Uploading the new war file to temporary location on server"
    if [ -e "$LOCAL_WAR_FILE" ]; then
        scp -i $PRIVATE_KEY_FILE "$LOCAL_WAR_FILE" devops@ubuntu:$TMP_UPLOAD_LOCATION
    else
        $WRITE_LOG "ERROR: Could not upload war file to temporary location on server"
        exit -1
    fi
}

# Take a backup of existing war file
function backup_existing_war_file()
{
    $WRITE_LOG "INFO: Taking a backup of existing war file in case we need to rollback"
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "if [ -e $REMOTE_WAR_FILE ]; then cp -f $REMOTE_WAR_FILE $BACKUP_WAR_FILE; fi"
    if [ $? -ne 0 ]; then
        $WRITE_LOG "ERROR: Could not take a backup of the existing war file"
        exit -1
    fi
}

# Fix the ownership of /var/lib/tomcat7 because hs2 db and its lock file cannot be written with wrong ownership
function fix_tomcat_dir_ownership()
{
    $WRITE_LOG "INFO: Fixing ownership of /var/lib/tomcat7 directory"
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S chown tomcat7.tomcat7 /var/lib/tomcat7"
    if [ $? -ne 0 ]; then
        $WRITE_LOG "ERROR: Could not fix the ownership of /var/lib/tomcat7"
        exit -1
    fi
}

# Deploy the new war file into tomcat
function deploy_new_war_file()
{
    $WRITE_LOG "INFO: Deploying the war file in tomcat"
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S systemctl stop tomcat7" && \
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S rm -rf $REMOTE_TOMCAT_DIR/webapps/ROOT*" && \
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S cp $TMP_UPLOAD_LOCATION $REMOTE_WAR_FILE" && \
    ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S systemctl start tomcat7"
    if [ $? -ne 0 ]; then
        $WRITE_LOG "ERROR: Could not deploy war file to the server"
        exit -1
    fi
    $WRITE_LOG "FINISH: All Done. War file has been deployed succesfully. You can now access the petclinic application in the browser."
}

# Now the rollback functionality
function rollback_to_previous_version()
{
    $WRITE_LOG "INFO: Attempting a rollback"
    if [ -e "$PRIVATE_KEY_FILE" ]; then
        ssh -i $PRIVATE_KEY_FILE devops@ubuntu "ls $BACKUP_WAR_FILE > /dev/null"
        if [ $? -eq 0 ]; then
            ssh -i $PRIVATE_KEY_FILE devops@ubuntu "diff $REMOTE_WAR_FILE $BACKUP_WAR_FILE"
            if [ $? -eq 0 ]; then
                $WRITE_LOG "WARNING: Old and new war files are the same. There is no point in rolling back. Quitting.."
                exit -1
            fi 
            ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S systemctl stop tomcat7" && \
            ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S rm -rf $REMOTE_TOMCAT_DIR/webapps/ROOT*" && \
            ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S cp $BACKUP_WAR_FILE $REMOTE_WAR_FILE" && \
            ssh -i $PRIVATE_KEY_FILE devops@ubuntu "cat $REMOTE_DEVOPS | sudo -p '' -S systemctl start tomcat7"
            if [ $? -ne 0 ]; then
                $WRITE_LOG "ERROR: Could not complete the rollback procedure"
                exit -1
            fi
        else
            $WRITE_LOG "ERROR: There is no backup war file that can be restored"
            exit -1
        fi
    else
        $WRITE_LOG "WARNING: You have not yet deployed any war file. So there is nothing to be restored"
        exit -1
    fi
    $WRITE_LOG "FINISH: Rollback completed successfully."
}
