alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'

alias gm='git submodule'
alias gmf='git submodule foreach'
alias gms='git submodule summary'
alias gmu='git submodule update'

# For each submodule print current local branch
gmb() {
       local gbc="git rev-parse --abbrev-ref HEAD"
       git submodule foreach \
		"if [ \$($gbc) != HEAD ]; \
                then echo \$($gbc); \
                else echo WARN: not on any branch; fi"
}

# For each sobmodule, list new commits on current branch not pushed to remote
gmn() {
	local remote=$1; remote=${remote:=origin}
	local gbc="git rev-parse --abbrev-ref HEAD"
	git submodule foreach \
		"if [ \$($gbc) != HEAD ]; \
		 then if git rev-parse $remote/\$($gbc) 2>/dev/null 1>&2; \
			 then git log --oneline $remote/\$($gbc)..\$($gbc); \
			 else echo WARN: no branch \$($gbc) in remote $remote; fi \
		 else echo WARN: not on any branch; fi"
}

# For each sobmodule, push the given branch if it exists
gmp() {
	local remote=$1; remote=${remote:=origin}
	local br="$2"
	git submodule foreach \
		"if git rev-parse $br 2>/dev/null 1>&2; \
		then echo git push $remote $br:$br && git push $remote $br:$br; \
		else echo WARN: no branch $br; fi"
}

# For each submdule, checkout the given branch if current hash matches; useful
# for re-attaching child repos to a branch after 'git sumodule update'.
gmk() {
	local branch=$1; branch=${branch:=master}
	local _RED='\033[0;31m'
	local _NOCOLOR='\033[0m'
	ERROR="${_RED}FAILED${_NOCOLOR}" git submodule foreach \
		"if [ \"\$(git rev-parse HEAD)\" = \"\$(git rev-parse $branch 2>/dev/null)\" ]; \
		then git checkout $branch; \
		else echo -e \"\$ERROR: not on branch $branch\" 1>&2; \
		fi"
}
