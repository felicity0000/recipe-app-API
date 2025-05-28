# Use a slim Python image
FROM python:3.9-alpine3.13
LABEL maintainer="enzo-john"

# Ensure stdout/stderr are unbuffered (good for Docker logging)
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Copy requirements first for better Docker cache
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Copy app code into container
COPY ./app /app

ARG DEV=false
# Install dependencies and create virtual environment
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
    # packages needed for postgresql adapter
      build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
      then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp/* && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Set virtual env path to default PATH
ENV PATH="/py/bin:$PATH"

# Use non-root user
USER django-user

# Expose port 8000 for development server or Gunicorn
EXPOSE 8000

# Optional: You can define a default CMD
# CMD ["gunicorn", "app.wsgi:application", "--bind", "0.0.0.0:8000"]
