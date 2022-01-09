## Minecraft Server

Automatically starts a server when visiting a URL, and terminates the instance when there no players online for 5-10
 minutes.

Requires a server folder minecraft/ containing all the server files and server.jar. This folder should be compressed
 into server_id.tar.gz, where server_id is the desired id of the server. I can be obtained by running `tar -czf server_id.tar.gz minecraft/`

To register a server first run `terraform apply` to set up the infrastructure (this doesn't need to be done for future
 servers), then move the server_id.tar.gz file into the created bucket minecraft-serversXXXXXXX. Add an entry in the
 created dynamodb table Servers with id=server_id and server_status=stopped.

To start or get the ip address of a server visit the api_url, with /server_id appended to the end.
e.g. https://voicjeyagg.execute-api.us-east-2.amazonaws.com/server/myserverid
To access the server in an administrative capacity, ssh into the server using the key specified in the variable
 ssh-key-pair-name and use `sudo screen -r minecraft`. The server files are located in the /minecraft folder.
