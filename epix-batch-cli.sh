#!/bin/bash
SEP=","
BATCHSIZE=10
EPIX_SERVICE="https://demo.ths-greifswald.de/epix/epixService"
#SOURCE="$(cat /dev/stdin)"
#HEAD="$(echo "$SOURCE" | head -n1)"
#DATA="$(echo "$SOURCE" | tail -n+2)"
#ORDER="$(echo "$DATA" | awk "{print \$s \"$SEP\" NR}" | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"

#REQE="$(echo "$SOURCE" | awk -F"$SEP" "NR == 1 {for(i=1;i<=NF;i++) { fn[i] = \$i }} NR > 1 { printf \"<requestEntries>\"; for(i=1;i<=NF;i++) { printf \"<%s>%s</%s>\",fn[i],\$i,fn[i] }; print \"</requestEntries>\" }")"
#REQH='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.epix.ttp.icmvc.emau.org/"><soapenv:Header/><soapenv:Body><ser:requestMPIBatch><mpiRequest><domainName>Demo</domainName>'
#REQF='<sourceName>dummy_safe_source</sourceName></mpiRequest></ser:requestMPIBatch></soapenv:Body></soapenv:Envelope>'

#NOL=$(echo "$REQE" | wc -l)
#for((i=1; i<=$NOL; i+=$BATCHSIZE)); do
#	n=$((i+BATCHSIZE-1))
#	n=$((n>NOL ? NOL : n))
#	echo "Lines $i to $n of $NOL"
#	echo "$REQE" | sed -n "$i,${n}p"
#done

REQH='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ser="http://service.epix.ttp.icmvc.emau.org/"><soapenv:Header/><soapenv:Body><ser:requestMPIBatch><mpiRequest><domainName>Demo</domainName>'
REQF='<sourceName>dummy_safe_source</sourceName></mpiRequest></ser:requestMPIBatch></soapenv:Body></soapenv:Envelope>'

i=0
REQE=""
DATA=""
cat /dev/stdin | \
awk -F"$SEP" "NR == 1 { for(i=1;i<=NF;i++) { fn[i] = \$i }; print } NR > 1 { printf \"<requestEntries>\"; for(i=1;i<=NF;i++) { printf \"<%s>%s</%s>\",fn[i],\$i,fn[i] }; printf \"</requestEntries>$SEP\"; print }" | {
read HEAD
XSLT="$(echo "$HEAD" | awk -F"$SEP" "{ printf \"<xsl:transform xmlns:xsl=\\\"http://www.w3.org/1999/XSL/Transform\\\" version=\\\"1.1\\\"><xsl:output method=\\\"text\\\" /><xsl:template match=\\\"/\\\"><xsl:for-each select=\\\"//entry\\\">\"; for(i=1;i<=NF;i++) { printf \"<xsl:value-of select=\\\"key/%s\\\" /><xsl:text>$SEP</xsl:text>\",\$i }; printf \"<xsl:value-of select=\\\"value/person/mpiId/value\\\" /><xsl:text>&#xa;</xsl:text></xsl:for-each></xsl:template></xsl:transform>\" }")"
while IFS= read line; do
	REQE+="$(echo "$line" | cut -d"$SEP" -f1 )"
	DATA+="$(echo "$line" | cut -d"$SEP" -f1 --complement )"$'\n'
	if [ $((++i)) -ge $BATCHSIZE ]; then
		ORDER="$(echo -n "$DATA" | awk "{print \$s \"$SEP\" NR}" | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
		curl --silent -X POST -H "Content-Type: text/xml" --data-binary "$REQH$REQE$REQF" "$EPIX_SERVICE" > debug
		RES=$(curl --silent -X POST -H "Content-Type: text/xml" --data-binary "$REQH$REQE$REQF" "$EPIX_SERVICE" | xsltproc <(echo "$XSLT") - | sort -t"$SEP" | paste -d"$SEP" <(echo "$ORDER") - | sort -t"$SEP" | cut -d"$SEP" -f1 --complement)
		echo "$RES"
		i=0
		REQE=""
		DATA=""
	fi
done
if [ $i -gt 0 ]; then
	ORDER="$(echo -n "$DATA" | awk "{print \$s \"$SEP\" NR}" | sort -t"$SEP" | rev | cut -d"$SEP" -f1 | rev)"
	RES=$(curl --silent -X POST -H "Content-Type: text/xml" --data-binary "$REQH$REQE$REQF" "$EPIX_SERVICE" | xsltproc <(echo "$XSLT") - | sort -t"$SEP" | paste -d"$SEP" <(echo "$ORDER") - | sort -t"$SEP" | cut -d"$SEP" -f1 --complement)
	echo "$RES"
	i=0
	REQE=""
	DATA=""
fi
}

