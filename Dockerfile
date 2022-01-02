FROM amazonlinux
RUN yum install -y yum-utils aws-cli
COPY aws-reposync.sh /usr/local/bin/aws-reposync.sh
RUN chmod +x /usr/local/bin/aws-reposync.sh
