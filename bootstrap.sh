#!/bin/bash
# The difference in sh & bash is whether to continue execute script or not when program had errors.

declare -a FILES_TO_SYMLINK=(
	"dot"
)

ask_for_confirmation() {
	# %b enable escape.
	printf "%b" "$1 (y/n [n])"
	# disable escape & read one character.
	read -r -n 1
	printf "\n"
}

answer_is_yes() {
	# $REPLY is default variable which save result of read command.
	[[ "$REPLY" =~ ^[Yy]$ ]] &&
		return 0 ||
		return 1
}

backup_target_file() {
	local suffix=".bak"
	local sourceFile=$1
	local targetFile="$2$suffix"
	# rename target file with .bak suffix when target file is not symlink.
	# `ln -fs` command will rm previous symlink
	if [ -L $sourceFile ]; then
		if [ -e $targetFile ]; then
			ask_for_confirmation "$targetFile already exists, do you want to overwrite it?"
			if answer_is_yes; then
				# rm previous .bak file
				rm -rf $targetFile
			fi
		fi
		cp -r $sourceFile $targetFile
	fi
}

create_symlink() {
	# the code below will rm previous symlink.
	ln -sf $1 $2
	echo "$2 symlink is installed."
}

install_dotfiles() {
	echo "------------------------------------Install dotfiles-----------------------------------"
	local sourceFile=""
	local targetFile=""
	local path=""
	for directory in "${FILES_TO_SYMLINK[@]}"; do
		path="$(pwd)/$directory"

		for filename in $(ls $directory); do

			sourceFile="$path/$filename"
			targetFile="$HOME/.$filename"

			# backup target file.
			backup_target_file $sourceFile $targetFile

			# create symlink.
			create_symlink $sourceFile $targetFile

		done
	done
	echo "---------------------------------dotfiles is installed!--------------------------------"
}

create_symlink_for_ohmyzsh() {
	local basepath="$(pwd)/zsh"
	local targetpath="$(pwd)/dot/oh-my-zsh"
	for directory in $(ls $basepath); do
		local dPath="$basepath/$directory"
		for filename in $(ls $dPath); do

			local sourceFile="$dPath/$filename"
			local targetFile="$targetpath/$directory/$filename"

			echo "sourceFile: $sourceFile"
			echo "targetFile: $targetFile"
			ln -fs $sourceFile $targetFile
		done
	done
}

is_git_repo() {
	git rev-parse &>/dev/null
}

get_origin_repo_url() {
	git remote -v
}

initialize_repo() {
	local REPO_URL="https://github.com/xpzero/dotfiles.git"

	if [[ ! is_git_repo || $(git config --get remote.origin.url) != "$REPO_URL" ]]; then

		echo "Initialize the Git repo."
		git init
		git remote add origin $REPO_URL
		echo "-----------------------------------start clone repo-------------------------------"
		git clone $REPO_URL --recurse-submodules
		if [ "$?" -eq 0 ]; then
			echo "-----------------------------------end clone repo---------------------------------"
			cd "dotfiles"
		else
			echo "repo clone failed. please retry."
			exit 1
		fi
	fi
}

initialize_repo
install_dotfiles
create_symlink_for_ohmyzsh
