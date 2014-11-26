This is my personal website.

Build using harp and docker.io

# Build the docker container

    docker build -t genuinegreg/homepage .


## Usage

    docker run -d \
        --restart=on-failure:3 \
        -p 9000 \
        --name homepage \
        genuinegreg/homepage