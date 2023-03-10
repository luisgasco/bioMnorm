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
RUN rm -r /srv/shiny-server/* && mkdir -p /srv/shiny-server/bioMnorm/renv && mkdir -p /srv/shiny-server/bioMnorm/data && mkdir -p /srv/shiny-server/bioMnorm/www && chown -R shiny:shiny /srv/shiny-server/bioMnorm




WORKDIR /bioMnorm
COPY renv.lock /srv/shiny-server/bioMnorm/
COPY renv/activate.R  /srv/shiny-server/bioMnorm/renv/
COPY renv/activate.R  /srv/shiny-server/bioMnorm/renv/
COPY .Rprofile /home/shiny/

# CHANGE TO USER
# AQUI CAMBIA DE USUARIO/PROPIETARIO EL ROOT https://www.r-bloggers.com/2021/08/setting-up-a-transparent-reproducible-r-environment-with-docker-renv/
# Habrá qu cambiar la ruta relativa de UI.R
COPY ui.R /srv/shiny-server/bioMnorm/
COPY global.R /srv/shiny-server/bioMnorm/
COPY server.R /srv/shiny-server/bioMnorm/
COPY .config_file /srv/shiny-server/bioMnorm/
COPY renv/* /srv/shiny-server/bioMnorm/renv/
COPY data/* /srv/shiny-server/bioMnorm/data/
COPY www/* /srv/shiny-server/bioMnorm/www/



WORKDIR /srv/shiny-server/bioMnorm
#RUN R -e "renv::hydrate()"
RUN R  -e "renv::restore(prompt=FALSE)"
#RUN R -e "renv::isolate()"


USER shiny
RUN R  -e "renv::restore(prompt=FALSE)"



# Entrar a srv/shiny-server/bioMnorm . A R y ejecutar renv:repair()
# Change to USER shiny and add permises so folder (ver error entrando dentro de BioMnorm a R (con R) y poniendo renv::restore(). Ahí dirá que no puede acceder a X folder)


#EXPOSE 3838

CMD ["/usr/bin/shiny-server"]

