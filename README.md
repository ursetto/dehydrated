## Setup

    # Create letsencrypt user, homedir /opt/letsencrypt
    mkdir /opt/letsencrypt/dehydrated
    cd /opt/letsencrypt/dehydrated

    git clone https://github.com/dehydrated-io/dehydrated src
    ln -s src/dehydrated .

    # output directory, readable only by our cert user and root
    install -d -o letsencrypt -g root -m 750 ./var

    # common well-known directory
    mkdir -p /var/www/acme-challenge/.well-known/acme-challenge
    chown letsencrypt /var/www/acme-challenge/.well-known/acme-challenge

    # Create ./config
    CA="letsencrypt"
    BASEDIR=${SCRIPTDIR}/var
    DOMAINS_TXT="${SCRIPTDIR}/domains.txt"
    WELLKNOWN="/var/www/acme-challenge/.well-known/acme-challenge"
    HOOK="${SCRIPTDIR}/hook.sh"
    CONTACT_EMAIL=jim@3e8.org

    # Update hook.sh. Modify deploy_cert() function:
    if [[ "$DOMAIN" = mail.* ]]; then
        service postfix reload &&
        service dovecot reload
    else
        service nginx reload
    fi

    # Set up sudoers for letsencrypt user
    cat > /etc/sudoers.d/letsencrypt <<EOF
    letsencrypt ALL=(ALL) NOPASSWD: /usr/sbin/service nginx reload, /usr/sbin/service postfix reload, /usr/sbin/service dovecot reload
    EOF

    # For testing, use `--ca letsencrypt-test` or place in config file

	./dehydrated --register
	./dehydrated --cron

	Add `dehydrated -c` to cron, running as letsencrypt user.

## Pros and cons

Pros:
- Flexible layout; can run without root, but with binaries/config owned by root
- Virtually no dependencies
- Per-domain config.
- Option overrides for most options.

Cons:
- Bought out by apilayer, who also bought acme.sh. It is almost certain that (like acme.sh)
  they will change the default CA to ZeroSSL at some point. It's also a bit dishonest to have
  the starving student spiel and Amazon/Paypal buttons now that the author is being employed
  to work on this project.
- Output is spammy, it poops to stdout even when it is not yet time to renew.
  Will probably cause spurious cron emails.
- Per-domain config is in directories that don't exist until the cert is requested. Better
  to use a single config file.
- Critical option WELLKNOWN cannot be overridden on command line. Need per-domain config or
  to use a single wellknown dir.
- Returns rc=0 even if renewal is not done, so `dehydrate && service nginx reload` will reload
  when not necessary. We must use hooks.
- Hooks are silly, every possible hook must be handled.
