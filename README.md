
## Remote execution plugin

It allows cloning a repo and executing shell commands on a remote server, pipeline env variables are exposed and available within remote shell

### Usage
 
 * Remote server should have SSH, BASH, GIT, RSYNC installed
 
 * Login using the SSH Key should be allowed on remote server
 
 * Git Trigger should be added to the pipeline to provide repo name and branch name variables to the step
 
 * SSH keys should be Base64 encoded:
 ```
 cat id_rsa | base64 -w0
 cat id_rsa.pub | base64 -w0
 ```
 
### Example:

```yaml
  remote_build:
    image: alexaladovcodefresh/sshtest
    cmd: "ls -la && pwd && env"
```

### Environment Variables

| Variables      | Required | Default | Description                                                                             |
|----------------|----------|---------|----------------------------------------------------------------------------------------|
| HOST_ADDRESS     | YES      |         | Remote server DNS name or IP address                                                |
| SSH_PORT   | YES      |         | SSH port on remote server                                                                 |
| SSH_PRV_KEY   | YES      |         | Base64 encoded private SSH key                              |
| SSH_PUB_KEY      | YES       |         | Base64 encoded public SSH key                                         |
| SSH_USERNAME  | YES       |         | SSH user name                                                        |  
| GIT_CONTEXT   | YES  |             | git context name from integrations with access to the repo
