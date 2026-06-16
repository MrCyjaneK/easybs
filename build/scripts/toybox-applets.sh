#!/bin/bash
# Applets symlinked by toybox-install.sh; enable matching CONFIG_* in toybox .config.

TOYBOX_APPLETS=(
    mkdir rm rmdir cp mv ln ls chmod touch cat echo pwd test true false
    dirname basename readlink realpath sed grep diff cmp awk head tail wc sort uniq cut tr
    printf env sleep seq tar gzip gunzip xz unxz find xargs tee stat uname date expr id which sh
)

toybox_enable_applets() {
    local applet cfg
    for applet in "${TOYBOX_APPLETS[@]}"; do
        cfg="CONFIG_${applet^^}"
        sed -i "s/# ${cfg} is not set/${cfg}=y/" .config
    done
}
