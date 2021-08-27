#!/bin/bash
SEP=","
BATCHSIZE=10
EPIX_SERVICE="https://demo.ths-greifswald.de/epix/epixService"

TEMP=`getopt -o hAUDd:b:c: --long help,add,update,remove,domain:,basedir:,ssl,nossl,nowildcardssl,acme-domain:,ssl-reload-cmd:,php,nophp,php-version:,nginx,nonginx,www,acme-sh: -n "${FUNCNAME}" -- "${@}"`

if [ $? != 0 ] ; then return 1 ; fi

eval set -- "${TEMP}";

while [[ ${1:0:1} = - ]]; do
	case $1 in
		-h|--help)
			cat <<EOF
USAGE: ${FUNCNAME} [OPTIONS] DOMAIN

OPTIONS

  -h --help		Print this help
  -d --delimiter	Set field delimiter (default: ${SEP})
  -b --batch		Request Master-Patient-Index in batches of # datasets (default: ${BATCHSIZE})
  -s --epix-service	Set E-PIX service URL (default: ${EPIX_SERVICE})

EOF
        								shift 1; return ;;
		--)							shift 1; break ;;
		-d|--delimiter)		local SEP="$2";			shift 2; continue ;;
		-b|--batch)		local BATCHSIZE="$2";		shift 2; continue ;;
		-s|--epix-service)	local EPIX_SERVICE="$2";	shift 2; continue ;;
	esac

	echo "ERROR: Unknown parameter ${1}"
	break;
done

function send_request() {
	REQE="$1"
	DATA="$(echo -n "$2")"
	REQH='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.epix.ttp.icmvc.emau.org/"><soapenv:Header/><soapenv:Body><ser:requestMPIBatch><mpiRequest><domainName>Demo</domainName>'
	REQF='<sourceName>dummy_safe_source</sourceName></mpiRequest></ser:requestMPIBatch></soapenv:Body></soapenv:Envelope>'
	ORDER="$(echo "$DATA" | awk -F"$SEP" '{print $0 FS NR}' | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
	COUNT="$(echo "$DATA" | awk -F"$SEP" '{d[$0]++} END{for(l in d){print l FS d[l]}}' | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
	echo "$(curl --silent -X POST -H "Content-Type: text/xml" --data-binary "$REQH$REQE$REQF" "$EPIX_SERVICE" | xsltproc <(echo "$XSLT") - | sort -t"$SEP" | paste -d"$SEP" <(echo "$COUNT") - | awk -F',' '{for(i=1;i<=$1;i++){print}}' | cut -d"$SEP" -f1 --complement | paste -d"$SEP" <(echo "$ORDER") - | sort -t"$SEP" | cut -d"$SEP" -f1 --complement | rev | cut -d"$SEP" -f1 | rev)"
}

i=0
REQE=""
DATA=""
cat /dev/stdin | \
awk -F"$SEP" 'NR == 1 { for(i=1;i<=NF;i++) { fn[i] = $i }; print } NR > 1 { printf "<requestEntries>"; for(i=1;i<=NF;i++) { printf "<%s>%s</%s>",fn[i],$i,fn[i] }; printf "</requestEntries>%c",FS; print }' | {
read HEAD
XSLT="$(echo "$HEAD" | awk -F"$SEP" '{ printf "<xsl:transform xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" version=\"1.1\"><xsl:output method=\"text\" /><xsl:template match=\"/\"><xsl:for-each select=\"//entry\">"; for(i=1;i<=NF;i++) { printf "<xsl:value-of select=\"key/%s\" /><xsl:text>%c</xsl:text>",$i,FS }; printf "<xsl:value-of select=\"value/person/mpiId/value\" /><xsl:text>&#xa;</xsl:text></xsl:for-each></xsl:template></xsl:transform>" }')"
while IFS= read line; do
	REQE+="$(echo "$line" | cut -d"$SEP" -f1 )"
	DATA+="$(echo "$line" | cut -d"$SEP" -f1 --complement )"$'\n'
	if [ $((++i)) -ge $BATCHSIZE ]; then
		send_request "$REQE" "$DATA"
		i=0; REQE=""; DATA=""
	fi
done
if [ $i -gt 0 ]; then
	send_request "$REQE" "$DATA"
fi
}

