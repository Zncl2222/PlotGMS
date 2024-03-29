FROM python:3.11-slim as base

RUN adduser --disabled-password pynecone


FROM base as build

WORKDIR /app
ENV VIRTUAL_ENV=/app/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY . .

RUN pip install --upgrade pip
RUN pip install wheel \
    && pip install -r requirements.txt


FROM base as runtime

RUN echo "deb http://opensource.nchc.org.tw/debian/ bullseye main" > /etc/apt/sources.list \
  && echo "deb http://opensource.nchc.org.tw/debian/ bullseye-updates main" >> /etc/apt/sources.list \
  && echo "deb http://opensource.nchc.org.tw/debian/ bullseye-proposed-updates main" >> /etc/apt/sources.list

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y curl

RUN curl -fsSL https://deb.nodesource.com/setup_19.x |  bash - \
    && apt-get update && apt-get install -y \
    nodejs \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/app/venv/bin:$PATH"

FROM runtime as init

WORKDIR /app
ENV BUN_INSTALL="/app/.bun"
COPY --from=build /app/ /app/
RUN pc init

FROM runtime

COPY --chown=pynecone --from=init /app/ /app/
USER pynecone
WORKDIR /app

CMD ["pc", "run", "--env", "dev"]

EXPOSE 3000
EXPOSE 8000
