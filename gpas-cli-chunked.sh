#!/bin/bash
SEP=","
CHUNKSIZE=10
GPAS_SERVICE="https://demo.ths-greifswald.de/gpas/gpasService"
DOMAIN="Studie A"

TEMP=`getopt -o hd:c:s:n: --long help,delimiter:,chunk:,gpas-service:,domain: -n "$(basename "$BASH_SOURCE")" -- "${@}"`

if [ $? != 0 ] ; then exit 1 ; fi

eval set -- "${TEMP}";

while [[ ${1:0:1} = - ]]; do
	case $1 in
		-h|--help)
			cat <<EOF
$(basename "$BASH_SOURCE") reads input from STDIN, sends it in batches to gPAS service
and returns pseudonyms ordered accordingly.

USAGE: $(basename "$BASH_SOURCE") [OPTIONS] < input
USAGE: cat input | $(basename "$BASH_SOURCE") [OPTIONS]

OPTIONS

  -h --help		Print this help
  -d --delimiter	Set field delimiter (default: ${SEP})
  -c --chunk		Request Master-Patient-Index in chunks of # datasets (default: ${CHUNKSIZE})
  -s --gpas-service	Set gPAS service URL (default: ${GPAS_SERVICE})
  -n --domain		Set gPAS domain (default: ${DOMAIN})

EOF
        							shift 1; exit ;;
		--)						shift 1; break ;;
		-d|--delimiter)		SEP="$2";		shift 2; continue ;;
		-c|--chunk)		CHUNKSIZE="$2";		shift 2; continue ;;
		-s|--gpas-service)	GPAS_SERVICE="$2";	shift 2; continue ;;
		-n|--domain)		DOMAIN="$2";		shift 2; continue ;;
	esac

	echo "ERROR: Unknown parameter ${1}"
	exit;
done

function send_request() {
	REQE="$1"
	DATA="$(echo -n "$2")"
	REQH='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:psn="http://psn.ttp.ganimed.icmvc.emau.org/"><soapenv:Header/><soapenv:Body><psn:getOrCreatePseudonymForList>'
	REQF='<domainName>'"$DOMAIN"'</domainName></psn:getOrCreatePseudonymForList></soapenv:Body></soapenv:Envelope>'
	ORDER="$(echo "$DATA" | awk -F"$SEP" '{print $0 FS NR}' | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
	COUNT="$(echo "$DATA" | awk -F"$SEP" '{d[$0]++} END{for(l in d){print l FS d[l]}}' | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
	echo "$(curl --silent -X POST -H "Content-Type: text/xml" --data-binary @<(echo "$REQH$REQE$REQF") "$GPAS_SERVICE" | xsltproc <(echo "$XSLT") - | sort -t"$SEP" | paste -d"$SEP" <(echo "$COUNT") - | awk -F',' '{for(i=1;i<=$1;i++){print}}' | cut -d"$SEP" -f1 --complement | paste -d"$SEP" <(echo "$ORDER") - | sort -nt"$SEP" | cut -d"$SEP" -f1 --complement | rev | cut -d"$SEP" -f1 | rev)"
}

i=0
REQE=""
DATA=""
XSLT='<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.1"><xsl:output method="text" /><xsl:template match="/"><xsl:for-each select="//entry"><xsl:value-of select="key" /><xsl:text>,</xsl:text><xsl:value-of select="value" /><xsl:text>&#xa;</xsl:text></xsl:for-each></xsl:template></xsl:transform>'
cat /dev/stdin | \
awk -F"$SEP" '{ printf "<values>%s</values>%c",$0,FS; print }' | {
while IFS= read line; do
	REQE+="$(echo "$line" | cut -d"$SEP" -f1 )"
	DATA+="$(echo "$line" | cut -d"$SEP" -f1 --complement )"$'\n'
	if [ $((++i)) -ge $CHUNKSIZE ]; then
		send_request "$REQE" "$DATA"
		i=0; REQE=""; DATA=""
	fi
done
if [ $i -gt 0 ]; then
	send_request "$REQE" "$DATA"
fi
}

