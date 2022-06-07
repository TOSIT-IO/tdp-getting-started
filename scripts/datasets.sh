#!/usr/bin/env bash

###
# Bash script to help users download sample datasets to use in hdfs
###

# Parameters

user_action=$1
user_dataset=$2

imdb=("https://datasets.imdbws.com/title.basics.tsv.gz" "title.basics.tsv" "gz" "bf98c321e036613a7e7f8e79c1c30566" "imdb" "csv")
nyctaxi=("https://data.cityofnewyork.us/api/views/djnb-wcxt/rows.csv" "2021_Green_Taxi_Trip_Data" "" "f75ed5085147e9181054941fc05b91dd" "nyctaxi" "csv")
#wiki=("https://ia800305.us.archive.org/15/items/wikidata-json-20150323/20150323.json.gz" "wikidata-json-20150323/20150323" "gz" "" "wiki" "json")
moby=("https://www.gutenberg.org/files/2701/2701-0.txt" "2701-0" "" "a1e490b38837162d2b83fea611c6c868" "moby" "txt")

sets=(imdb nyctaxi moby)

# Helper Functions

# TODO add options for converting files
# Parse args for help flags
while getopts 'h' options; do
  case "$options" in
  h) print_usage && exit 0 ;;
  esac
done

print_usage() {
  echo """
  tdp-gs --help

  Usage: tdp-gs [options] [COMMAND] [args]

  Commands:

  tdp-gs datasets                      Display datasets downloaded
  tdp-gs download all                  Download all datasets (or the ones missing) and move to hdfs.
  tdp-gs download <name>               Download and move to hdfs selected file (if not missing)
  tdp-gs delete <name>                 Deletes the dataset

  Options:

  -h, --help                           Display help information
  """
}

stderr_exit() {
  printf '%s\n' "$1" >&2 # Send message to stderr.
  exit "${2-1}" # Return a code specified by $2, or 1 by default.
}

file_exists() {
  hdfs dfs -test -f "datasets/$file_folder/$file_name.$file_extension"
}

print_datasets() { # TODO: Modify to impler format after using xml
  echo "Datasets available to download are:"
  echo -e """
  Dataset\t   -   Format
  ${imdb[4]}\t   -   ${imdb[5]}
  ${nyctaxi[4]}\t   -   ${nyctaxi[5]}
  ${moby[4]}\t   -   ${moby[5]}
  """ | column -t -s $'\t'
  echo "Datasets already available in HDFS:"
  hdfs dfs -ls datasets | column -t -s $'\t'
}

# Main Functions

parse_first_argument() {
  kinit -kt /home/tdp_user/tdp_user.keytab tdp_user@REALM.TDP
  if [[ $user_action == "datasets" ]]; then
      (print_datasets) && exit 1
  elif [[ $user_action == 'download' ]]; then
      (parse_download_argument $user_dataset) || stderr_exit "Didn't download $user_dataset"
  elif [[ $user_action == 'delete' ]]; then
      (parse_delete_argument $user_dataset) || stderr_exit "Didn't delete $user_dataset"
  else
      print_usage && stderr_exit "Command was not valid"
  fi
  echo "Datasets already available in HDFS:"
  hdfs dfs -ls datasets | column -t -s $'\t'
}

parse_download_argument() {
  if [[ "${user_dataset}" == "all" ]]; then
      (all_datasets input_datasets download_dataset)
  elif [[ " ${sets[*]} " =~ " ${user_dataset} " ]]; then
      (input_datasets $user_dataset download_dataset)
  else
      print_usage && exit 1
  fi
}

parse_delete_argument() {
  if [[ " ${sets[*]} " =~ " ${user_dataset} " ]]; then  #$string == *"My long"*
      (input_datasets $user_dataset delete_dataset)
  else
      print_usage && exit 1
  fi
}
 
all_datasets() {
  for data_set in "${sets[@]}"; do
    ($1 $data_set $2)
  done
}

input_datasets() {
  case $1 in
    imdb) ($2 "${imdb[@]}")  ;;
    nyctaxi) ($2 "${nyctaxi[@]}")  ;;
    moby) ($2 "${moby[@]}")  ;;
  esac
}

download_dataset() {
  file_url=$1
  file_name=$2
  file_compression=$3
  file_checksum=$4
  file_extension=$6
  file_folder=$5
  
  (file_exists $file_name $file_extension $file_folder) && stderr_exit "$file_folder already exists"
  if [ -z "$file_compression" ]; then # If compression is null
    wget -O "/tmp/$file_name.$file_extension" "$file_url"
  elif [ "$file_compression" = "gz" ]; then
    wget -O- "$file_url" | gzip -d --no-name > "/tmp/$file_name.$file_extension"
  else
    print_usage && exit 1
  fi
  if [ "$file_folder" != "imdb" ]; then #imdb changes daily so there's no sense to validate checksum until they provide it
    md5=($(md5sum "/tmp/$file_name.$file_extension"))
    [[ $file_checksum == $md5 ]] || stderr_exit "Dataset checksum doesn't match the original files"
  fi
  move_hdfs
}

delete_dataset() {
  hdfs dfs -rm -r datasets/$5
}

move_hdfs() {
  hdfs dfs -mkdir -p datasets/$file_folder
  hdfs dfs -put /tmp/$file_name.$file_extension /user/tdp_user/datasets/$file_folder
}

parse_first_argument user_action user_dataset
