#!/bin/sh

CURRENT_DIR="${CURRENT_DIR:=$(cd $(dirname $0) && pwd -P)}"

CRYPTREST_GIT_BRANCH="${CRYPTREST_GIT_BRANCH:=master}"
CRYPTREST_GIT_URL="https://github.com/cryptrest/installer/archive/$CRYPTREST_GIT_BRANCH.tar.gz"

CRYPTREST_TITLE='CryptREST'
CRYPTREST_DIR="$HOME/.cryptrest"
CRYPTREST_ENV_FILE="$CRYPTREST_DIR/.env"
CRYPTREST_OPT_DIR="$CRYPTREST_DIR/opt"
CRYPTREST_BIN_DIR="$CRYPTREST_DIR/bin"
CRYPTREST_BIN_INIT_FILE="$CRYPTREST_BIN_DIR/cryptrest-init"
CRYPTREST_SRC_DIR="$CRYPTREST_DIR/src"
CRYPTREST_ETC_DIR="$CRYPTREST_DIR/etc"
CRYPTREST_WWW_DIR="$CRYPTREST_DIR/www"
CRYPTREST_TMP_DIR="${TMPDIR:=/tmp}/cryptrest"
CRYPTREST_INSTALLER_DIR="$CRYPTREST_DIR/installer-$CRYPTREST_GIT_BRANCH"
CRYPTREST_INSTALLER_FILE="$CRYPTREST_INSTALLER_DIR/bin.sh"
CRYPTREST_WWW_INSTALLER_DIR="$CRYPTREST_WWW_DIR/installer"
CRYPTREST_WWW_INSTALLER_HTML_FILE="$CRYPTREST_WWW_INSTALLER_DIR/index.html"

CRYPTREST_MODULES='nginx letsencrypt go'
CRYPTREST_IS_LOCAL=1
CRYPTREST_HOME_SHELL_PROFILE_FILES=".bashrc .mkshrc .zshrc"


cryptrest_is_local()
{
    for i in $CRYPTREST_MODULES; do
        if [ -d "$CURRENT_DIR/$i" ] && [ -f "$CURRENT_DIR/$i/install.sh" ]; then
            CRYPTREST_IS_LOCAL=0
            break
        fi
    done

    return $CRYPTREST_IS_LOCAL
}

cryptrest_init_file()
{
    echo '#!/bin/sh' > "$CRYPTREST_BIN_INIT_FILE"
    echo '' >> "$CRYPTREST_BIN_INIT_FILE"
    echo "CURRENT_DIR=\"\${CURRENT_DIR:=\$(cd \$(dirname \$0) && pwd -P)}\"" >> "$CRYPTREST_BIN_INIT_FILE"
    echo '' >> "$CRYPTREST_BIN_INIT_FILE"
    echo ". \"\$CURRENT_DIR/../.env\"" >> "$CRYPTREST_BIN_INIT_FILE"
    echo '' >> "$CRYPTREST_BIN_INIT_FILE"
    echo ". \"\$CRYPTREST_DIR/opt/letsencrypt/renew.sh\"" >> "$CRYPTREST_BIN_INIT_FILE"

    chmod 500 "$CRYPTREST_BIN_INIT_FILE"
}

cryptrest_init()
{
    rm -f "$CRYPTREST_ENV_FILE" && \
    rm -f "$CRYPTREST_BIN_DIR/cryptrest-in"* && \
    rm -rf "$CRYPTREST_WWW_INSTALLER_DIR" && \
    mkdir -p "$CRYPTREST_DIR" && \
    chmod 700 "$CRYPTREST_DIR" && \
    mkdir -p "$CRYPTREST_OPT_DIR" && \
    chmod 700 "$CRYPTREST_OPT_DIR" && \
    mkdir -p "$CRYPTREST_SRC_DIR" && \
    chmod 700 "$CRYPTREST_SRC_DIR" && \
    mkdir -p "$CRYPTREST_BIN_DIR" && \
    chmod 700 "$CRYPTREST_BIN_DIR" && \
    mkdir -p "$CRYPTREST_ETC_DIR" && \
    chmod 700 "$CRYPTREST_ETC_DIR" && \
    mkdir -p "$CRYPTREST_WWW_DIR" && \
    chmod 700 "$CRYPTREST_WWW_DIR" && \
    mkdir -p "$CRYPTREST_WWW_INSTALLER_DIR" && \
    chmod 700 "$CRYPTREST_WWW_INSTALLER_DIR" && \
    mkdir -p "$CRYPTREST_TMP_DIR" && \
    chmod 700 "$CRYPTREST_TMP_DIR" && \
    mkdir -p "$CRYPTREST_INSTALLER_DIR" && \
    chmod 700 "$CRYPTREST_INSTALLER_DIR" && \
    echo '' > "$CRYPTREST_ENV_FILE" && \
    chmod 600 "$CRYPTREST_ENV_FILE" && \
    echo "# $CRYPTREST_TITLE" > "$CRYPTREST_ENV_FILE"
    echo "export CRYPTREST_DIR=\"$HOME/.cryptrest\"" >> "$CRYPTREST_ENV_FILE"
    echo "export PATH=\"\$PATH:\$CRYPTREST_DIR/bin\"" >> "$CRYPTREST_ENV_FILE"
    echo '' >> "$CRYPTREST_ENV_FILE"

    echo ''
    echo "$CRYPTREST_TITLE structure: init"
}

cryptrest_local()
{
    echo "$CRYPTREST_TITLE mode: local"
    echo ''

    for i in $CRYPTREST_MODULES; do
        . "$CURRENT_DIR/$i/install.sh"
        [ $? -ne 0 ] && return 1
    done

    cp "$CURRENT_DIR/bin.sh" "$CRYPTREST_WWW_INSTALLER_HTML_FILE" && \
    return 0
}

cryptrest_download()
{
    cd "$CRYPTREST_DIR" && \
    curl -SL "$CRYPTREST_GIT_URL" | tar -xz
    if [ $? -ne 0 ]; then
        echo "$CRYPTREST_TITLE: Some errors with download"
        rm -rf "$CRYPTREST_DIR"

        exit 1
    fi
}

cryptrest_network()
{
    echo "$CRYPTREST_TITLE mode: network"
    echo ''

    cryptrest_download && \
    chmod 700 "$CRYPTREST_DIR" && \
    cp "$CRYPTREST_INSTALLER_FILE" "$CRYPTREST_WWW_INSTALLER_HTML_FILE" && \
    "$CRYPTREST_INSTALLER_FILE"
}

cryptrest_define()
{
    local profile_file=''

    cryptrest_init_file && \
    chmod 444 "$CRYPTREST_WWW_INSTALLER_HTML_FILE" && \
    chmod 400 "$CRYPTREST_ENV_FILE" && \
    chmod 500 "$CRYPTREST_INSTALLER_FILE" && \
    ln -s "$CRYPTREST_INSTALLER_FILE" "$CRYPTREST_BIN_DIR/cryptrest-installer" && \

    if [ $? -eq 0 ]; then
        echo ''
        echo "$CRYPTREST_TITLE ENV added in following profile file(s):"

        for shell_profile_file in $CRYPTREST_HOME_SHELL_PROFILE_FILES; do
            profile_file="$HOME/$shell_profile_file"

            if [ -f "$profile_file" ]; then
                echo '' >> "$profile_file"
                echo "# $CRYPTREST_TITLE" >> "$profile_file"
                echo ". \$HOME/.cryptrest/.env" >> "$profile_file"

               echo "    '$profile_file"
            fi
        done

        echo ''
        echo "$CRYPTREST_TITLE installation successfully completed!"
        echo ''
    fi
}

cryptrest_install()
{
    local status=0

    cryptrest_is_local
    if [ $? -eq 0 ]; then
        cryptrest_local && \
        if [ $? -eq 0 ]; then
            status=0

            if [ "$CURRENT_DIR" != "$CRYPTREST_INSTALLER_DIR" ]; then
                rm -f "$CRYPTREST_INSTALLER_DIR/bin.sh" && \
                cp "$CURRENT_DIR/bin.sh" "$CRYPTREST_INSTALLER_DIR/bin.sh"
                status=$?
            fi
        else
            status=1
        fi
        [ $status -eq 0 ] && cryptrest_define
    else
        cryptrest_network
    fi
}


cryptrest_init && \
cryptrest_install
