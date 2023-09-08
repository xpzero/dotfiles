#!/bin/bash
# The difference in sh & bash is whether to continue execute script or not when program had errors.

shPath="$(pwd)/$(basename $0)"
if [[ -e $shPath && -x $shPath ]]; then
	chmod +x "$shPath"
else
	# if want to catch exception and output yours info, using echo command in else.
	echo "$shPath is not exists."
	exit 1
fi

# read filename in dot/.
dotPath="$(pwd)/dot"
dotFiles=$(ls $dotPath)

echo "------------------------------------Install dotfiles-----------------------------------"
for filename in $dotFiles; do
	sourceFile="$dotPath/$filename"
	targetFile="$HOME/.$filename"
	ln -sf $sourceFile $targetFile
	echo "$HOME/.$filename symlink is installed."
done

echo "---------------------------------dotfiles is installed!--------------------------------"
