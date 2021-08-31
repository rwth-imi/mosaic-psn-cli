# MOSAIC CLI chunked
This repository provides tools written in `bash` to convert an input file of identifying data to Master-Patient-Indices (MPIs) using the E-PIX service from the MOSAIC toolset. For further processing the MPIs can be exchanged with pseudonyms for specific requesting domains using the gPAS service.

The input file is processed as a stream and send to the services in chunks using the list methods. The output will be in the same order as the input, so each input line has a corresponding output line at the same line number, except of a headline in the input file which declares the input fields.

## Options
Both tools can be configured with command line arguments.

### epix-cli-chunked.sh
```txt
epix-cli-chunked.sh reads input from STDIN, sends it in batches to E-PIX service
and returns Master-Patient-Indices (MPIs) ordered accordingly.

USAGE: epix-cli-chunked.sh [OPTIONS] < input.csv
USAGE: cat input.csv | epix-cli-chunked.sh [OPTIONS]

OPTIONS

  -h --help		Print this help
  -d --delimiter	Set field delimiter (default: ,)
  -b --batch		Request Master-Patient-Index in batches of # datasets (default: 10)
  -s --epix-service	Set E-PIX service URL (default: https://demo.ths-greifswald.de/epix/epixService)
  -n --domain		Set E-PIX domain (default: Demo)
  -e --source		Set E-PIX source (default: dummy_safe_source)
```

### gpas-cli-chunked.sh
```txt
gpas-cli-chunked.sh reads input from STDIN, sends it in batches to gPAS service
and returns pseudonyms ordered accordingly.

USAGE: gpas-cli-chunked.sh [OPTIONS] < input
USAGE: cat input | gpas-cli-chunked.sh [OPTIONS]

OPTIONS

  -h --help		Print this help
  -d --delimiter	Set field delimiter (default: ,)
  -b --batch		Request Master-Patient-Index in batches of # datasets (default: 10)
  -s --gpas-service	Set gPAS service URL (default: https://demo.ths-greifswald.de/gpas/gpasService)
  -n --domain		Set gPAS domain (default: Studie A)
```

## Example
Assuming the following example data in the file `IDAT`:
```txt
firstName,lastName,birthDate,gender
Max,Musterfrau,2001-02-03,X
Luise,Mustermann,2004-05-06,U
Max2,Musterfrau,2001-02-03,X
Luise2,Mustermann,2004-05-06,U
Max3,Musterfrau,2001-02-03,X
Luise3,Mustermann,2004-05-06,U
Max,Musterfrau,2001-02-03,X
Luise,Mustermann,2004-05-06,U
Max2,Musterfrau,2001-02-03,X
Luise2,Mustermann,2004-05-06,U
Max3,Musterfrau,2001-02-03,X
Max123,Musterfrau,2001-02-03,X
```

Generating MPIs:
```sh
cat IDAT | ./epix-cli-chunked.sh
```

Or moving further generating pseudonyms:
```sh
cat IDAT | ./epix-cli-chunked.sh | ./gpas-cli-chunked.sh
```

