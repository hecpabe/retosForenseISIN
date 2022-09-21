#!/bin/bash

# Constantes
ipsFile="ips.txt"
auxFile="aux.txt"
usersCompromisedFile="usersCompromised.txt"
suspiciousIPsCount=1000

# Variables
logFile=$1
arrayLength=0
array=()
suspiciousIPs=()
suspiciousIPsLength=0
currentIP=""
IPsCount=0
actions=()
actionsLength=0
usersCompromised=()
usersCompromisedLength=0
currentUser=""
compromisedDate=""
compromisedUser=""

# === IPs Implicadas ===
# Extraer IPs que han fallado al iniciar sesión y las veces que lo han hecho
grep "Failed password for" $logFile | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" | sort | uniq -c | sort -r > $ipsFile

# Guardarlo en un array
readarray -t array < $ipsFile
arrayLength=${#array[@]}
arrayLength=$(($arrayLength - 1))

# Mostrar IPs sospechosas
echo ""
echo "---------- IPs sospechosas ----------"
for i in $(seq 0 $arrayLength);
do
	currentIP=$(echo ${array[$i]} | awk '{print $2}')
	IPsCount=$(echo ${array[$i]} | awk '{print $1}')
	if [ -z "$IPsCount" ]
	then
		echo ""
	else
		if [ $IPsCount -gt $suspiciousIPsCount ]
		then
			suspiciousIPs+=($currentIP)
			echo -e "IP: ${currentIP} \t | Intentos fallidos: ${IPsCount}"
		fi
	fi
done
echo "-------------------------------------"

# === Cuando han ocurrido los principales ataques de cada IP sospechosa ===
echo ""
echo "---------- Fechas de principales ataques ----------"
suspiciousIPsLength=${#suspiciousIPs[@]}
suspiciousIPsLength=$(($suspiciousIPsLength - 1))

for i in $(seq 0 $suspiciousIPsLength);
do
	currentIP=$(echo ${suspiciousIPs[$i]})
	attackDate=$(grep "Failed password for" $logFile | grep $currentIP | cut -c 1-12 | uniq -c | sort -r | head -n 1)
	numberOfAttempts=$(echo $attackDate | awk '{print $1}')
	attackMonth=$(echo $attackDate | awk '{print $2}')
	attackDay=$(echo $attackDate | awk '{print $3}')
	attackTime=$(echo $attackDate | awk '{print $4}')

	echo -e "IP: ${currentIP} \t | Fecha: ${attackMonth} ${attackDay} ${attackTime} \t | Intentos: ${numberOfAttempts}"
done
echo "---------------------------------------------------"

# === Cuando el ataque ha tenido exito ===
echo ""
echo "---------- Fechas de primer acceso ----------"

for i in $(seq 0 $suspiciousIPsLength);
do
	currentIP=$(echo ${suspiciousIPs[$i]})
	accessDate=$(grep "Accepted password for" $logFile | grep $currentIP | head -n 1 | cut -c 1-15)
	if [ -z "$accessDate" ]
	then
		accessDate="Ninguna"
	fi
	echo -e "IP: ${currentIP} \t | Fecha: ${accessDate}"
done
echo "---------------------------------------------"

# === Acciones post explotación realizadas ===
echo ""
echo "---------- Acciones post-explotación IP ----------"

for i in $(seq 0 $suspiciousIPsLength);
do
	currentIP=$(echo ${suspiciousIPs[$i]})
	grep $currentIP $logFile | grep -v "Failed password for" | grep -v "Invalid user" | grep -v "authentication failure" > $auxFile
	readarray -t actions < $auxFile
	actionsLength=${#actions[@]}
	actionsLength=$(($actionsLength - 1))
	echo "--- IP ${currentIP} ---"
	for j in $(seq 0 $actionsLength);
	do
		echo ${actions[$j]}
	done
done
echo "--------------------------------------------------"

# Sacamos los usuarios comprometidos
echo ""
echo "---------- Usuarios Comprometidos ----------"

for i in $(seq 0 $suspiciousIPsLength);
do
	currentIP=$(echo ${suspiciousIPs[$i]})
	if [ $i -lt 1 ]
	then
		grep "Accepted password for" $logFile | grep $currentIP | awk '{print $1, $2, $3, $9}' | uniq > $auxFile
	else
		grep "Accepted password for" $logFile | grep $currentIP | awk '{print $1, $2, $3, $9}' | uniq >> $auxFile
	fi
done

# Eliminamos los que son iguales
cat $auxFile | sort -u -t" " -k4,1 > $usersCompromisedFile

# Lo guardamos en un array
readarray -t usersCompromised < $usersCompromisedFile
usersCompromisedLength=${#usersCompromised[@]}
usersCompromisedLength=$(($usersCompromisedLength - 1))


# Mostramos los usuarios comprometidos
for i in $(seq 0 $usersCompromisedLength);
do
	currentUser=$(echo ${usersCompromised[$i]})
	compromisedDate=$(echo $currentUser | awk '{print $1, $2, $3}')
	compromisedUser=$(echo $currentUser | awk '{print $4}')
	echo -e "Usuario: ${compromisedUser} \t | Fecha: ${compromisedDate}"
done

echo "--------------------------------------------"

# Pasamos por los diferentes accesos buscando las acciones que han realizado
echo ""
echo "---------- Acciones post-explotación Usuarios ----------"

for i in $(seq 0 $usersCompromisedLength);
do
	currentUser=$(echo ${usersCompromised[$i]})
	compromisedDate=$(echo $currentUser | awk '{print $1, $2, $3}')
	compromisedUser=$(echo $currentUser | awk '{print $4}')
	echo "--- User ${compromisedUser} ---"
	grep $compromisedUser $logFile | grep -v "Failed password for" | grep -v "session opened" | grep -v "session closed" | grep -v "authentication failure" | awk -v compromisedDateAWK="$compromisedDate" '$0 > compromisedDateAWK' > $auxFile
	readarray -t actions < $auxFile
	actionsLength=${#actions[@]}
	actionsLength=$(($actionsLength - 1))
	for j in $(seq 0 $actionsLength);
	do
		echo ${actions[$j]}
	done
done
echo "---------------------------------------------------------"

# Eliminamos los ficheros auxiliares
rm $ipsFile
rm $auxFile
rm $usersCompromisedFile
