FROM redmine:3.4 AS builder

# Install requirements (mostly for bundle install/update)
RUN apt update &&\
  apt upgrade -y &&\
    apt install -y make gcc ruby-dev libffi-dev g++

# Fetch plugins
WORKDIR /usr/src/redmine/

# Plugins @Github
RUN su redmine -c \
  "git clone https://github.com/hicknhack-software/redmine_hourglass.git \
    plugins/redmine_hourglass &&\
  git clone https://github.com/devopskube/redmine_openid_connect.git \
    plugins/redmine_openid_connect &&\
  git clone --single-branch --branch redmine-3.4 \
    https://github.com/paginagmbh/redmine_lightbox2.git \
      plugins/redmine_lightbox2 &&\
  git clone https://github.com/jcppkkk/redmine_mail_reminder.git \
    plugins/redmine_mail_reminder &&\
  git clone https://github.com/giddie/redmine_default_assign.git \
    plugins/redmine_default_assign &&\
  git clone https://github.com/dhanasingh/redmine_wktime.git \
    plugins/redmine_wktime"

# Plugins we can't retrieve from public sources (wget, git, etc.)
COPY --chown=redmine:redmine ./plugins/ ./plugins/
RUN su redmine -c bundle update && bundle install

# Multi-stage to get rid of build dependencies
FROM redmine:3.4
# Copy gems from builder
WORKDIR /usr/local/bundle/
COPY --from=builder --chown=redmine:redmine /usr/local/bundle/ .
# Copy redmine (w/ plugins) from builder
WORKDIR /usr/src/redmine/
COPY --from=builder --chown=redmine:redmine /usr/src/redmine/ .

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
