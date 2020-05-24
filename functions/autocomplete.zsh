# compdef _axiom-ssh axiom-ssh
# compdef _axiom-ssh axiom-rm
# compdef _axiom-ssh axiom-backup
# compdef _axiom-restore axiom-restore

function _axiom-ssh(){
	local state
	_arguments "1: :($(doctl compute droplet list | awk '{ print $2 }' | grep -v 'Name' | tr '\n' ' '))"
}

function _axiom-restore(){
	local state
	_arguments "1: :($(ls ~/.axiom/boxes/))"
}
