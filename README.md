Nginx OpenAM policy agent build
===

Nginx openam module (thanks for it hamano! https://bitbucket.org/hamano/nginx-mod-am) is an OpenAM policy agent for Nginx. With every release of the module, a new Nginx binary is released with the module embedded. This is great and is the way to go if you don't need any extra modules in Nginx (you can get it here: http://bugster.forgerock.org/jira/browse/OPENAM-1182). However, if you need to add any other module, you'll find that building the policy agent isn't a funny task to do (dependencies, platform specific tweaks, versions, etc). This is an attempt of making the process straightforward using Docker containers.

### Dependencies

  - Docker (https://docs.docker.com/installation/)  

### Checkout the code and set it up

    git clone https://github.com/tegioz/nginx_openam_build
    cd nginx_openam_build

Now you have to add your Forgerock username and password to the Dockerfile. During the process we'll need to checkout OpenAM source code and you need to be logged in to do that. Just edit these two lines in the Dockerfile:

    ENV FORGEROCK_USERNAME your_username_here
    ENV FORGEROCK_PASSWORD your_password_here

### Now you are ready to build your Nginx OpenAM policy agent

The build process will take some time, please be patient :)

    docker build -t nginx-openam-build .
    docker run --rm nginx-openam-build > nginx_Linux_64_agent_4.0.0-SNAPSHOT.zip

That's it!

### How to use the policy agent

More information: https://bitbucket.org/hamano/nginx-mod-am

### Want to add more Nginx modules? 

In the Docker file there is a section identified by this header (EXTRA NGINX MODULES TO ADD) in which an extra sample module (redis2-nginx-module) is added to the Nginx build. You can use it as an example to add as many as you want.

### Playing with the nginx_openam_build Docker image

If you prefer not modifying the Dockerfile you can create a container using the image you just built and open an interactive bash session. This way you'll have a full environment with everything you need to build the policy agent again, adding now some extra modules you might be interested in (/tmp/opensso/products/webagents/agents/source/nginx/Makefile is a good place to look at in this case).

To create a container based on the image previously built and open an interactive session just run this command:

    docker run -ti nginx-openam-build bash

You can commit any changes you have made to your container to a new image, although updating the Dockerfile to include your modules is probably a better way to go.

Enjoy!
