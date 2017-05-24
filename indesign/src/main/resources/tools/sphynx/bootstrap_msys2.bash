## 
pacman -S --needed --noconfirm make python python3-setuptools mingw-w64-x86_64-gcc

if [[ ! -z $(which pip) ]]
then

	pip install sphinx

	## https://github.com/snide/sphinx_rtd_theme
	pip install sphinx_rtd_theme

elif [[ ! -z $(which pip) ]]
then

	pip3 install sphinx

	## https://github.com/snide/sphinx_rtd_theme
	pip3 install sphinx_rtd_theme

elif [[ ! -z $(which easy_install) ]]
then

	easy_install sphinx
	easy_install sphinx_rtd_theme
fi