# Edit `config` and set CA=letsencrypt-test for testing.
# Symlink or create domains.txt with site domains to register.

# `make init` to register, `make setup` to set up system for renewal, `make activate` to activate certs
# `make renew` to force renewal

# If you switch from test to normal mode, you need to register (once) and force renew.

register:
	./dehydrated --register --accept-terms

setup:
	@[ -f domains.txt ] || { echo; echo '*** Please symlink or create domains.txt' 2>&1; exit 1; }
	install -d -o letsencrypt -g root -m 750 ./var
	install -d -o letsencrypt -g root -m 755 /var/www/acme-challenge/.well-known/acme-challenge
	chown -R letsencrypt:root ./var
	@visudo -c >/dev/null
	install -o root -g root -m 440 sudoers /etc/sudoers.d/letsencrypt
	visudo -c >/dev/null
	@echo
	@echo "*** Manual steps:"
	@echo "    install -m 755 -o root -g root acme.conf /etc/nginx/snippets/acme.conf"
	@echo '    # Add to /etc/nginx/sites-available/*'
	@echo '    include snippets/acme.conf;'
	@echo

activate: setup
	install -m 755 -o root -g root cron /etc/cron.daily/dehydrated
	@echo
	@echo "*** Manual steps:"
	@echo '    # Add to /etc/nginx/sites-available/*'
	@echo "    ssl_certificate_key `pwd`/var/certs/<site>/privkey.pem;"
	@echo "    ssl_certificate `pwd`/var/certs/<site>/fullchain.pem;"
	@echo

clone:
	git clone https://github.com/dehydrated-io/dehydrated ./src

renew:
	./dehydrated -c -x
	chown -R letsencrypt:root ./var

.PHONY: setup install renew
