###########
# BUILDER #
###########

# pull official base image
FROM python:3.9.6-alpine as builder

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install psycopg2 dependencies
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

# install dependencies
COPY ./install/requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /usr/src/app/wheels -r requirements.txt


#########
# FINAL #
#########

# pull official base image
FROM python:3.9.6-alpine

# create directory for the app user
RUN mkdir -p /web_root

# create the app user
RUN addgroup -S docker && adduser -S docker -G docker

# create the appropriate directories
ENV WEB_ROOT=/web_root
# Root project folder
ENV PROJECT_ROOT=$WEB_ROOT/conf
RUN mkdir $PROJECT_ROOT
WORKDIR $PROJECT_ROOT

# install dependencies
RUN apk update && apk add libpq
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .
RUN pip install --no-cache /wheels/*

# copy entrypoint.sh
COPY ./docker/entrypoint.sh .
RUN sed -i 's/\r$//g'  $PROJECT_ROOT/entrypoint.sh

# copy project
COPY . $PROJECT_ROOT

# chown all the files to the app user
RUN chown -R docker:docker $PROJECT_ROOT

RUN chmod +x $PROJECT_ROOT/entrypoint.sh

# change to the app user
USER docker

# run entrypoint
ENTRYPOINT ["./entrypoint.sh"]
CMD ["run_project"]

# Expose port 8000
EXPOSE 8000

# # install psycopg2 dependencies
# RUN apk update \
#     && apk add postgresql-dev gcc python3-dev musl-dev jpeg-dev zlib-dev
