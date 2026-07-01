docker rm -f floci floci-ssl floci-backend nginx-proxy

docker network rm floci-network

docker network create floci-network
