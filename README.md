# dehydrated config

This is personal config for my domains.

## Setup

We install [dehydrated](https://github.com/dehydrated-io/dehydrated) and its config files as root
under `/opt/letsencrypt`, but run it as the regular user `letsencrypt`, with all output into `./var`.
`sudo` access is granted to `letsencrypt` to restart services after certs are issued.
This will run daily from cron, and renew only when <= 30 days remain until expiration.

    # Create letsencrypt user, with homedir /opt/letsencrypt

    mkdir /opt/letsencrypt/dehydrated
    cd /opt/letsencrypt/dehydrated

    # We already include a copy of dehydrated inline for convenience and safety.
    # If you want to update it, run:

    make clone
    cp src/dehydrated .

    # Create or symlink domains.txt for all your domains (see upstream docs for complex setups).
    # Generally no other config needs to be done (except possibly changing email in `config`).
    ln -s domains-3e8.txt domains.txt

    # Run setup, which will set up ./var, the common acme-challenge root in `/var/www/acme-challenge`,
    # and the sudo access. Manually configure nginx to respond to challenges,
    # usually by including snippets/acme.conf in your server blocks.

    make setup

    # Register an account (make sure you set `CA=letsencrypt-test` in `config` while testing)

    make register

    # Run a renewal 

    make renew

    # Run activation, which sets up cron and prods you to configure the new SSL certs
    # in nginx (and maybe postfix).

    make activate

## Config

Config is set up so that all output defaults to ./var (we override BASEDIR for that).
The only thing you might need to change is the email address.

    CA="letsencrypt"
    BASEDIR=${SCRIPTDIR}/var
    DOMAINS_TXT="${SCRIPTDIR}/domains.txt"
    WELLKNOWN="/var/www/acme-challenge/.well-known/acme-challenge"
    HOOK="${SCRIPTDIR}/hook.sh"
    CONTACT_EMAIL=<email>

For service restart we modify the `deploy_cert` hook to reload nginx config by default;
if the domain starts with "mail.", then restart postfix instead.

    # Update hook.sh. Modify deploy_cert() function:
    if [[ "$DOMAIN" = mail.* ]]; then
        service postfix reload &&
        service dovecot reload
    else
        service nginx reload
    fi

## Testing

For testing, use `--ca letsencrypt-test` or place in config file as `CA=letsencrypt-test`
(if using the `Makefile`).

	./dehydrated --register
	./dehydrated --cron

## Pros and cons

Pros:

- Flexible layout; can run without root, but with binaries/config owned by root
- Virtually no dependencies. Don't need a big venv or recent python or cryptography libs.
- Per-domain config.
- Option overrides for most options.

Cons:

- Bought out by apilayer, who also bought acme.sh. It is almost certain that (like acme.sh)
  they will change the default CA to ZeroSSL at some point.
- Output is spammy, it poops to stdout even when it is not yet time to renew, causing
  spurious daily cron emails. Mitigated with special processing in cron script. 
- Per-domain config is in directories that don't exist until the cert is requested. Better
  to use a single config file.
- Critical option WELLKNOWN cannot be overridden on command line. Need per-domain config or
  to use a single wellknown dir.
- Returns rc=0 even if renewal is not done, so `dehydrate && service nginx reload` will reload
  when not necessary. We must use hooks.
- Hooks are annoying, every possible hook must be present, even just doing nothing.
