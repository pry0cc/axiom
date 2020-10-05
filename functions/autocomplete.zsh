# compdef _axiom-ssh axiom-ssh
# compdef _axiom-ssh axiom-rm
# compdef _axiom-ssh axiom-backup
# compdef _axiom-restore axiom-restore

function _axiom-ssh(){
	local state
	_arguments "1: :($(~/.axiom/interact/axiom-ls --list|  tr '\n' ' '))"
}

function _axiom-restore(){
	local state
	_arguments "1: :($(ls ~/.axiom/boxes/))"
}
function _axiom-deploy(){
	local state
	_arguments "1: :($(ls ~/.axiom/profiles/))"
}
