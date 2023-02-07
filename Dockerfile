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


USER shiny

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
ENV RENV_PATHS_LIBRARY renv/library

RUN Rscript -e 'renv::restore()'

# approach two
#RUN mkdir -p renv
#COPY .Rprofile .Rprofile
#COPY renv/activate.R renv/activate.R
#COPY renv/settings.dcf renv/settings.dcf
#RUN R -e "renv::restore()"


#ENV _R_SHLIB_STRIP_=true
#COPY Rprofile.site /etc/R
#RUN install2.r --error --skipinstalled \
#    shiny \
#    jsonlite \
#    htmltools

COPY ./app/* /srv/shiny-server/


#EXPOSE 3838

CMD ["/usr/bin/shiny-server"]

