

##############################

count=""
path=""
size=""
modificationTime=""
name=""

properUsageMessage()
{
  echo "Use me as below"
  echo "$0 -p path [-c count] [-s size] [-t modification-time] [-n name-suffix for files]"
  echo "Default values --"
  echo "    count = 1"
  echo "    size  = 10K"
  echo "    modification time = current time"
  echo "    name-suffix = file"
  echo
}

processCommandLineParameters()
{
while getopts ":c:C:p:P:s:S:t:T:hHn:N:" opt; do

  case $opt in
    c | C)
      count=$OPTARG
      ;;

    p | P)
      path=$OPTARG
      ;;

    s | S)
      size=$OPTARG
      ;;

    t | T)
      modificationTime=$OPTARG
      ;;

    h | H)
      properUsageMessage
      exit 0
      ;;

    n | N)
      name=$OPTARG
      ;;

    :)
      echo "Error : $OPTARG requires parameter"
      properUsageMessage
      exit 1
      ;;

    \?)
      echo "$OPTARG is unknown parameter"
      properUsageMessage
      exit 1
      ;;
    esac
done

if [ "$path" == "" ]; then
  properUsageMessage
  exit 1
elif [ ${path: -1} != "/" ]; then
  path+="/"
fi


if [ "$count" == "" ]; then
  count=1
fi

if [ "$size" == "" ]; then
  size="10K"
fi

if [ "$name" == "" ]; then
  name="file"
fi
}


##############################

processCommandLineParameters "$@"

for (( c=1; c<=$count; c++ ))
do
  fileName="$name"$c
  fileName="$path$fileName"
  dd if=/dev/zero of="$fileName" bs=$size count=1
done

if [ "$modificationTime" != "" ]; then
  for (( c=1; c<=$count; c++ ))
  do
    fileName="$name"$c
    fileName="$path$fileName"
    touch -d "$modificationTime" "$fileName"
  done
fi
