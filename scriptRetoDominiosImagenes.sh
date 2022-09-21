

pagWeb=$1
ficheroHTML="index.html"
ficheroAuxiliar="aux.txt"
ficheroDominios="dom.txt"
dominios=()
dominionsLength=0
dominioActual=""
IPActual=""

wget -q $1

echo "---------- Dominios ----------"
cat $ficheroHTML | grep "<img" | grep -o "src=\"https://[!-z]\+" | cut -c 14- | awk -F/ '{print $1}' | sort | uniq
cat $ficheroHTML | grep "<img" | grep -o "src=\"https://[!-z]\+" | cut -c 14- | awk -F/ '{print $1}' | sort | uniq > $ficheroAuxiliar
echo "------------------------------"

cat $ficheroAuxiliar | awk -F. '{print $2 "." $3}' | sort | uniq > $ficheroDominios

readarray -t dominios < $ficheroDominios
dominiosLength=${#dominios[@]}
dominiosLength=$((dominiosLength - 1))

for i in $(seq 0 $dominiosLength);
do
	dominioActual=$(echo ${dominios[$i]})
	IPActual=$(host $dominioActual | grep "has address" | awk '{print $4}')
done

rm $ficheroHTML
