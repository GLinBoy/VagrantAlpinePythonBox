echo "  ____ _     _       ____              "
echo " / ___| |   (_)_ __ | __ )  ___  _   _ "
echo "| |  _| |   | | '_ \|  _ \ / _ \| | | |"
echo "| |_| | |___| | | | | |_) | (_) | |_| |"
echo " \____|_____|_|_| |_|____/ \___/ \__, |"
echo "        #define Hojjat Abedie    |___/ "
echo
export LANG=C.UTF-8
export GPG_KEY=0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
export PYTHON_VERSION=3.7.2
export PYTHON_PIP_VERSION=18.1
apk add --no-cache ca-certificates;
set -ex;
apk add --no-cache --virtual .fetch-deps gnupg tar xz;
wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz";
wget -O python.tar.xz.asc "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc";
export GNUPGHOME="$(mktemp -d)";
gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY";
gpg --batch --verify python.tar.xz.asc python.tar.xz  && { command -v gpgconf > /dev/null && gpgconf --kill all || :; };
rm -rf "$GNUPGHOME" python.tar.xz.asc;
mkdir -p /usr/src/python;
tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz;
rm python.tar.xz;
apk add --no-cache --virtual .build-deps bzip2-dev coreutils dpkg-dev dpkg expat-dev findutils gcc gdbm-dev libc-dev libffi-dev libnsl-dev libressl-dev libtirpc-dev linux-headers make ncurses-dev pax-utils readline-dev sqlite-dev tcl-dev tk tk-dev util-linux-dev xz-dev zlib-dev git openssh;
apk del .fetch-deps;
cd /usr/src/python;
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)";
./configure --build="$gnuArch" --enable-loadable-sqlite-extensions --enable-shared --with-system-expat --with-system-ffi --without-ensurepip;
make -j "$(nproc)" EXTRA_CFLAGS="-DTHREAD_STACK_SIZE=0x100000";
make install;
find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';'  | tr ',' '\n'  | sort -u  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'  | xargs -rt apk add --no-cache --virtual .python-rundeps;
apk del .build-deps;
find /usr/local -depth  \(  \( -type d -a \( -name test -o -name tests \) \)  -o  \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \)  \) -exec rm -rf '{}' +;
rm -rf /usr/src/python;
python3 --version;
cd /usr/local/bin;
ln -s idle3 idle;
ln -s pydoc3 pydoc;
ln -s python3 python;
ln -s python3-config python-config;
set -ex;
wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py';
python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION";
pip --version;
find /usr/local -depth \(  \( -type d -a \( -name test -o -name tests \) \)  -o  \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \)  \) -exec rm -rf '{}' +;
rm -f get-pip.py;
pip install virtualenv;
echo Finished, Enjoy it...
