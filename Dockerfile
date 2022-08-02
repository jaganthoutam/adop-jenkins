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
    
# Install Java 11
ENV JAVA_HOME=/opt/openjdk-11
ENV PATH=$JAVA_HOME/bin:$PATH

ENV JAVA_VERSION=11.0.2
ENV JAVA_URL=https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
ENV JAVA_SHA256=99be79935354f5c0df1ad293620ea36d13f48ec3ea870c838f20c504c9668b57

RUN set -eux; \
    \
    wget -O /openjdk.tgz "${JAVA_URL}"; \
    echo "${JAVA_SHA256} */openjdk.tgz" | sha256sum -c -; \
    mkdir -p "${JAVA_HOME}"; \
    tar --extract --file /openjdk.tgz --directory "${JAVA_HOME}" --strip-components 1; \
    rm /openjdk.tgz;

# Environment variables
ENV ADOP_LDAP_ENABLED=true LDAP_IS_MODIFIABLE=true ADOP_ACL_ENABLED=true ADOP_SONAR_ENABLED=true ADOP_ANT_ENABLED=true ADOP_MAVEN_ENABLED=true ADOP_NODEJS_ENABLED=true ADOP_GITLAB_ENABLED=true
ENV LDAP_GROUP_NAME_ADMIN=""
ENV JENKINS_OPTS="--prefix=/jenkins -Djenkins.install.runSetupWizard=false"
ENV PLUGGABLE_SCM_PROVIDER_PROPERTIES_PATH="/var/jenkins_home/userContent/datastore/pluggable/scm"
ENV PLUGGABLE_SCM_PROVIDER_PATH="/var/jenkins_home/userContent/job_dsl_additional_classpath/"

RUN jenkins-plugin-cli --plugins $(/usr/share/jenkins/ref/plugins.txt)
RUN echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group14-sha256,diffie-hellman-group1-sha1" >> /etc/ssh/ssh_config

ENTRYPOINT ["/entrypoint.sh"]
