ARG SOURCE_IMAGE_NAME="${SOURCE_IMAGE_NAME:-bazzite-gnome}"
ARG TARGET_IMAGE_NAME="${TARGET_IMAGE_NAME:-geekos}"

FROM scratch AS ctx
COPY build_files /

FROM ghcr.io/ublue-os/${SOURCE_IMAGE_NAME}:stable AS geekos

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

RUN bootc container lint

FROM ghcr.io/ublue-os/${SOURCE_IMAGE_NAME}:stable AS geekos-nvidia

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit

RUN bootc container lint