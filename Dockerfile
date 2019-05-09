FROM alpine
RUN apk add openssh-client bash rsync jq curl \
&& mkdir -p /root/.ssh \
&& chmod 0700 /root/.ssh \
&& echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
&& rm -rf /var/cache/apk/*
COPY entrypoint.sh /entrypoint.sh
COPY cf-git-clone.sh /cf-git-clone.sh
ENTRYPOINT ["/entrypoint.sh"] 
