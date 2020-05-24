function _axiom(){
	local state
	_arguments "1: :($(doctl compute droplet list | awk '{ print $2 }' | grep -v 'Name' | tr '\n' ' '))"
}
