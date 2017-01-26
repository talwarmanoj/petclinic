#!/bin/bash

# AUTHOR      : Manoj Talwar
# EMAIL       : talwarmanoj@gmail.com
# DESCRIPTION : Main script for grails-petclinic war file deployment (or rollback)

source helperfiles/env_vars.sh
source helperfiles/petclinic_functions.sh

case "$1" in
    deploy)
        start_with_clean_slate
        check_for_sshpass_package
        deal_with_ssh_keypair
        clone_repo_from_github
        generate_new_war_file
        upload_war_tmp_location
        backup_existing_war_file
        fix_tomcat_dir_ownership
        deploy_new_war_file
        ;;
    rollback)
        check_for_sshpass_package
        rollback_to_previous_version
        ;;
    *)
        echo "    Usage: petclinic_war.sh deploy[|rollback]"
        ;;
esac
