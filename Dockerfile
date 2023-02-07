FROM rocker/shiny:4.2.0
# Install system requirements for index.R as needed
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    git-core \
    libssl-dev \
    libsasl2-dev \
    libz-dev \
    pkg-config \
    libcurl4-gnutls-dev \
    curl \
    libsodium-dev \
    libxml2-dev \
    libicu-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get -y update
RUN apt-get -y install vim nano



# GET FILES
RUN git clone https://github.com/luisgasco/bioMnorm.git

# ENVIRONMMENT
ENV RENV_VERSION 0.16.0
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"


#Install
WORKDIR /bioMnorm
COPY renv.lock renv.lock
# approach one
# ENV RENV_PATHS_LIBRARY renv/library
# RUN Rscript -e 'renv::restore()'

# Give permissions 
RUN chmod -R 777 /bioMnorm/renv

# approach two (ESTO YA ESTA TEORICAMENTE en bioMnorm)
RUN mkdir -p renv 
COPY .Rprofile .Rprofile 
COPY renv/activate.R renv/activate.R 
COPY renv/settings.dcf renv/settings.dcf 
RUN R -e "renv::restore()"
RUN R -e "renv::isolate()"
# RUN R -e "renv::restore()"
# RUN chmod -R 777 /bioMnorm/renv/library/R-4.2/x86_64-pc-linux-gnu
#RUN R -e "renv::repair()"

RUN ls -la
RUN rm -r /srv/shiny-server/*

# CHANGE TO USER
USER shiny
# AQUI CAMBIA DE USUARIO/PROPIETARIO EL ROOT https://www.r-bloggers.com/2021/08/setting-up-a-transparent-reproducible-r-environment-with-docker-renv/
COPY app/* /srv/shiny-server/bioMnorm/app/
COPY renv/* /srv/shiny-server/bioMnorm/renv/
COPY data/* /srv/shiny-server/bioMnorm/data/
COPY www/* /srv/shiny-server/bioMnorm/www/


# Change to USER shiny and add permises so folder (ver error entrando dentro de BioMnorm a R (con R) y poniendo renv::restore(). Ahí dirá que no puede acceder a X folder)


#EXPOSE 3838

CMD ["/usr/bin/shiny-server"]

