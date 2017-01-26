# Petclinic deployment automation

### Deployment 
In order to deploy the war file to tomcat, simply clone this repository and then run:

    bash petclinic_war.sh deploy

for deploying a newly created war file to the tomcat server.
##### Note: Before running the deploy, please ensure that the hostname of deployment server i.e. ubuntu should be resovable either via DNS or via an entry in /etc/hosts

### Rollback
To rollback to the previous war file run:

    bash petclinic_war.sh rollback
    
### Meeting the requirements criteria
Here is an explanation of how my solution meets the requirements:
1. The war file deployed by my soltion runs as the root context i.e. http://ubuntu:8080 in comparison to http://ubuntu:8080/petclinic
2. With this solution, developers do not need server access.
3. With my solution, only those users that have been authorised by sysadmin can run the deployments/rollbacks.
4. And finally, the rollback funtionality has been inbuilt into the solution. War files can be rolled back by passing 'rollback' as argument to the main script.
