

pagWeb=$1
dominioABuscar=$2
ficheroHTML="index.html"

wget -q $1

echo "---------- URLs ----------"
cat $ficheroHTML | grep -oE "\"http[s]{0,1}://[#-z]+\"" | cut -c 2- | rev | cut -c 2- | rev | grep $dominioABuscar | uniq
echo "--------------------------"

rm $ficheroHTML
