for pkg in $(grep -vE "^\s*#" build/packages.add | tr "\n" " ")
do
  apt -y --no-install-recommends install $pkg
done

