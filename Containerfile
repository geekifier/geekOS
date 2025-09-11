ARG SOURCE_IMAGE_NAME="${SOURCE_IMAGE_NAME:-bazzite-gnome}"
ARG TARGET_IMAGE_NAME="${TARGET_IMAGE_NAME:-geekos}"

FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/${SOURCE_IMAGE_NAME}:stable AS geekos

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/090-repos.sh && \
    /ctx/100-system_packages.sh && \
    /ctx/util/finalize_layer.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/109-optfix.sh && \
    /ctx/util/optfix.sh && \
    /ctx/110-desktop_packages.sh && \
    /ctx/util/finalize_layer.sh
    
RUN bootc container lint

FROM geekos AS geekos-test

RUN --mount=type=secret,id=rootpass \
      bash -eu -c ' \
        [ -f /run/secrets/rootpass ] && { \
          echo ":: setting temporary root password for test stage"; \
          passwd --stdin < /run/secrets/rootpass; \
        } || echo ":: rootpass secret not provided; skipping"'

FROM ghcr.io/ublue-os/${SOURCE_IMAGE_NAME}:stable AS geekos-nvidia

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/090-repos.sh && \
    /ctx/100-system_packages.sh && \
    /ctx/util/finalize_layer.sh

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/109-optfix.sh && \
    /ctx/util/optfix.sh && \
    /ctx/110-desktop_packages.sh && \
    /ctx/util/finalize_layer.sh
    
RUN bootc container lint

FROM geekos-nvidia AS geekos-nvidia-test

RUN --mount=type=secret,id=rootpass \
      bash -eu -c ' \
        [ -f /run/secrets/rootpass ] && { \
          echo ":: setting temporary root password for test stage"; \
          passwd --stdin < /run/secrets/rootpass; \
        } || echo ":: rootpass secret not provided; skipping"'