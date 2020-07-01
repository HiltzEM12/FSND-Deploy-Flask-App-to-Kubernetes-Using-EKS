FROM python:stretch

RUN mkdir /app

COPY . /app
WORKDIR /app

RUN pip install --upgrade pip
RUN pip install -r requirements.txt


ENTRYPOINT [ "gunicorn" , "-b", ":8080", "main:APP"]

# Buid this image using the code below.  The . indicates that the dockerfile is in the current directory:
#
# docker build -t jwt-api-test .
#
# Run the container using the code below:
# 
# docker run  -p 80:8080 jwt-api-test
#
# Check the port via a curl using the code below in another console:
#
# curl localhost:80
#
# To get the id of the running container, use the following code:
#
# docker ps
#
# Then use the id of the container to stop it via:
#
# docker stop <Container Id>