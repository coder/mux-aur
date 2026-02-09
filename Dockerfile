FROM archlinux:latest

# Install tooling needed for AUR package builds.
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
      base-devel \
      bun \
      git \
      jq \
      nodejs \
      npm \
      sudo && \
    pacman -Scc --noconfirm

# makepkg must run as a non-root user.
RUN useradd -m -u 1000 builder && \
    printf "builder ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/builder

WORKDIR /work
COPY . /work
RUN chown -R builder:builder /work

USER builder

# Build the package and leave artifacts in /work.
CMD ["bash", "-lc", "makepkg --syncdeps --noconfirm --cleanbuild --clean"]
