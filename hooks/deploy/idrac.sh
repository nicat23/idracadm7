#!/usr/bin/env sh
# idrac.sh Usage:
#
# Put this script in /hooks/deploy/idrac.sh (which overlays into /acmebin/deploy/idrac.sh)
#
# export DEPLOY_IDRAC_HOST="HOST"
# export DEPLOY_IDRAC_PASS="PASSWORD"
# export DEPLOY_IDRAC_USER="USER"
#
# acme.sh --issue --dns dns_cf -d "HOST" -k 2048
# acme.sh --deploy -d "HOST" --deploy-hook idrac

idrac_deploy() {
	_cdomain="$1"
	_ckey="$2"
	_ccert="$3"
	_cca="$4"
	_cfullchain="$5"

	_debug _cdomain "$_cdomain"
	_debug _ckey "$_ckey"
	_debug _ccert "$_ccert"
	_debug _cca "$_cca"
	_debug _cfullchain "$_cfullchain"

	_getdeployconf Le_Deploy_idrac_user
	_getdeployconf Le_Deploy_idrac_pass
	_getdeployconf Le_Deploy_idrac_host

	if [ -z "$Le_Deploy_idrac_user" ] || [ -z "$Le_Deploy_idrac_pass" ] || [ -z "$Le_Deploy_idrac_host" ]; then
		if [ -z "$DEPLOY_IDRAC_USER" ] || [ -z "$DEPLOY_IDRAC_PASS" ] || [ -z "$DEPLOY_IDRAC_HOST" ]; then
			_err "Both deployment configuration and environment variables are missing. Please set them."
			_err "Usage examples:"
			_err "export DEPLOY_IDRAC_HOST=\"HOST\""
			_err "export DEPLOY_IDRAC_PASS=\"PASSWORD\""
			_err "export DEPLOY_IDRAC_USER=\"USER\""
			_err "acme.sh --issue --dns dns_cf -d \"HOST\" -k 2048"
			_err "acme.sh --deploy -d \"HOST\" --deploy-hook idrac"
			return 1
		else
			Le_Deploy_idrac_user="$DEPLOY_IDRAC_USER"
			Le_Deploy_idrac_pass="$DEPLOY_IDRAC_PASS"
			Le_Deploy_idrac_host="$DEPLOY_IDRAC_HOST"
			_savedeployconf Le_Deploy_idrac_user "$Le_Deploy_idrac_user"
			_savedeployconf Le_Deploy_idrac_pass "$Le_Deploy_idrac_pass"
			_savedeployconf Le_Deploy_idrac_host "$Le_Deploy_idrac_host"
		fi
	fi

	# Ensure Dell RACADM shared libraries remain resolvable inside subshells
	export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-/opt/dell/srvadmin/lib64:/usr/lib64:/usr/lib:/lib}"

	_info "Starting iDRAC deployment"
	_debug2 Le_Deploy_idrac_user "$Le_Deploy_idrac_user"
	_debug2 Le_Deploy_idrac_host "$Le_Deploy_idrac_host"

	_info "Uploading SSL key to $Le_Deploy_idrac_host"
	if ! _out=$(racadm --nocertwarn -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslkeyupload -t 1 -f "$_ckey" 2>&1); then
		_err "Failed to upload SSL key: $_out"
		return 1
	fi
	_debug "$_out"

	_info "Uploading SSL certificate to $Le_Deploy_idrac_host"
	if ! _out=$(racadm --nocertwarn -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" sslcertupload -t 1 -f "$_cfullchain" 2>&1); then
		_err "Failed to upload SSL certificate: $_out"
		return 1
	fi
	_debug "$_out"

	_info "Resetting iDRAC on $Le_Deploy_idrac_host"
	if ! _out=$(racadm --nocertwarn -r "$Le_Deploy_idrac_host" -u "$Le_Deploy_idrac_user" -p "$Le_Deploy_idrac_pass" racreset 2>&1); then
		_err "Failed to reset iDRAC: $_out"
		return 1
	fi
	_debug "$_out"

	_info "iDRAC deployment finished successfully"
	return 0
}