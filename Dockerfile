FROM debian:12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:0.7.21 /uv /uvx /bin/

ENV UV_MANAGED_PYTHON=1
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV UV_PYTHON_INSTALL_DIR=/tmp/python
ENV UV_PROJECT_ENVIRONMENT=/usr/local

ARG UV_NO_EDITABLE=1
ENV UV_NO_EDITABLE=${UV_NO_EDITABLE}

RUN apt-get update \
 && apt-get install -y dpkg-dev
RUN MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH) \
 && mkdir -p /opt/lib/$MULTIARCH \
 && cp /usr/lib/$MULTIARCH/libz.so.1 /opt/lib/$MULTIARCH/libz.so.1

WORKDIR /app

COPY .python-version ./scripts/install_python.sh ./
RUN ./install_python.sh

# Workspace members' pyproject.toml files are required for sync
COPY ./libs ./libs
COPY ./services/sso/pyproject.toml ./services/sso/pyproject.toml
COPY ./services/surgical/pyproject.toml ./services/surgical/pyproject.toml

RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev --package surgical

COPY .python-version ./patches ./scripts/apply_patch.sh ./
RUN ./apply_patch.sh fastapi_filter

FROM gcr.io/distroless/cc-debian12
COPY --from=builder --chown=nonroot:nonroot /usr/local /usr/local
COPY --from=builder /opt/lib /usr/lib

USER nonroot
WORKDIR /app

ENV PATH=/usr/local/bin:$PATH
COPY services/sso ./sso
COPY services/surgical ./surgical

ENTRYPOINT [ "python" ]
