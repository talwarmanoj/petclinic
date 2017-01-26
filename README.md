# Petclinic deployment automation

### Deployment 
In order to run this solution, simply clone the repository and run:

    ./petclinic_war.sh deploy

for deploying a newly created war file to the tomcat server.
##### Note: Before running the deploy, please ensure that the hostname of deployment server i.e. ubuntu should be resovable either via DNS or via an entry in /etc/hosts

### Rollback
To rollback to the previous war file run:

    ./petclinic_war.sh rollback
