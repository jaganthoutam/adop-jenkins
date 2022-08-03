FROM jenkins/jenkins:latest

MAINTAINER Jagadish Thoutam

ENV GITLAB_HOST_NAME gitlab
ENV GITLAB_PORT 80
ENV GITLAB_SSH_PORT 22

# Copy in configuration files
COPY resources/plugins.txt /usr/share/jenkins/ref/
COPY resources/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
COPY resources/scripts/ /usr/share/jenkins/ref/adop_scripts/
COPY resources/jobs/ /usr/share/jenkins/ref/jobs/
COPY resources/views/ /usr/share/jenkins/ref/init.groovy.d/
COPY resources/m2/ /usr/share/jenkins/ref/.m2
COPY resources/entrypoint.sh /entrypoint.sh
COPY resources/scriptApproval.xml /usr/share/jenkins/ref/

# Reprotect
USER root
COPY resources/jenkins.sh /usr/local/bin/jenkins.sh
RUN chmod +x -R /usr/local/bin/jenkins.sh
RUN chmod +x -R /usr/share/jenkins/ref/plugins.txt
RUN chmod +x -R /usr/share/jenkins/ref/adop_scripts/ && \
    chmod +x /entrypoint.sh
# USER jenkins

# Install Docker
RUN apt-get -qq update && \
    apt-get -qq -y install curl && \
    curl -sSL https://get.docker.com/ | sh 
    
RUN usermod -aG docker jenkins
    
# Install Maven
RUN apt-get install -y maven

#Install Ansible
RUN apt-get install -y ansible

# Install kubectl and helm
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash


# Environment variables
ENV ADOP_LDAP_ENABLED=true LDAP_IS_MODIFIABLE=true ADOP_ACL_ENABLED=true ADOP_SONAR_ENABLED=true ADOP_ANT_ENABLED=true ADOP_MAVEN_ENABLED=true ADOP_NODEJS_ENABLED=true ADOP_GITLAB_ENABLED=true
ENV LDAP_GROUP_NAME_ADMIN=""
ENV JENKINS_OPTS="--prefix=/jenkins -Djenkins.install.runSetupWizard=false"
ENV PLUGGABLE_SCM_PROVIDER_PROPERTIES_PATH="/var/jenkins_home/userContent/datastore/pluggable/scm"
ENV PLUGGABLE_SCM_PROVIDER_PATH="/var/jenkins_home/userContent/job_dsl_additional_classpath/"

RUN jenkins-plugin-cli --plugins $(/usr/share/jenkins/ref/plugins.txt)
RUN echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group14-sha256,diffie-hellman-group1-sha1" >> /etc/ssh/ssh_config

ENTRYPOINT ["/entrypoint.sh"]
