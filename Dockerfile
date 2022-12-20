FROM devkitpro/devkitppc

RUN apt update && apt install -y wget

RUN ln -s /proc/mounts /etc/mtab

RUN wget https://wii.leseratte10.de/devkitPro/devkitPPC/r35/devkitPPC-r35-1-linux.pkg.tar.xz && \
    wget https://wii.leseratte10.de/devkitPro/devkitARM/r53%20%282019-06%29/devkitARM-r53-1-linux.pkg.tar.xz && \
    wget https://wii.leseratte10.de/devkitPro/libogc/libogc_1.8.23%20%282019-10-02%29/libogc-1.8.23-1-any.pkg.tar.xz

RUN rm  /opt/devkitpro/devkitPPC/bin/powerpc-eabi-gdb \
        /opt/devkitpro/devkitPPC/bin/powerpc-eabi-run \
        /opt/devkitpro/devkitPPC/include/gdb/jit-reader.h \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/amd64-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/gdb-syscalls.dtd \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/i386-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/mips-n32-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/mips-n64-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/mips-o32-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/ppc-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/ppc64-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/sparc-linux.xml \
        /opt/devkitpro/devkitPPC/share/gdb/syscalls/sparc64-linux.xml

RUN dkp-pacman --noconfirm -U devkitARM-r53-1-linux.pkg.tar.xz && \
    dkp-pacman --noconfirm -U libogc-1.8.23-1-any.pkg.tar.xz && \
    dkp-pacman --noconfirm -U devkitPPC-r35-1-linux.pkg.tar.xz

RUN rm devkitPPC-r35-1-linux.pkg.tar.xz && \
    rm devkitARM-r53-1-linux.pkg.tar.xz && \
    rm libogc-1.8.23-1-any.pkg.tar.xz

# ENV DEVKITPPC=${DEVKITPRO}/devkitPPC
# ENV DEVKITARM=/opt/devkitpro/devkitARM

# RUN . /etc/profile.d/devkit-env.sh
