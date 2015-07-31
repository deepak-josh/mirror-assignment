

#########Colors
RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';

########Error messages

wrongUsageMessage(){
  echo "Use me as below"
  echo "$0 -l local-path -r remote-path -a archiveDays"
  echo
}

error(){
  echo -e "${BYel}Error :${Yel}$1${RCol}"
  exit 1
}

###########

local=""
remote=""
remoteUserName="josh"
remoteIP="172.16.10.128"
archiveDays=""
localArchivePath="/home/josh/Desktop/archive21/"
remoteArchivePath="/home/josh/Desktop/archive21/"

############

archiveOldFiles(){
  echo "archiving old files..."

  # on local
  mkdir -p $localArchivePath

  find $local -mtime +$(($archiveDays-1)) -exec mv {} "$localArchivePath" \;

  #on server

  ssh $remoteUserName@$remoteIP "mkdir -p \"$remoteArchivePath\""

  ssh $remoteUserName@$remoteIP "find \"$remote\" -mtime +$(($archiveDays-1)) -exec mv {} \"$remoteArchivePath\" \;"

  echo "archiving files complete."
  echo ""
}

processCommandLineParameters()
{
while getopts ":l:L:r:R:a:A:hH" opt; do
  case $opt in
    a | A)
      archiveDays=$OPTARG
      ;;

    l | L)
      local=$OPTARG
      ;;

    r | R)
      remote=$OPTARG
      ;;

    :)
      echo "$OPTARG requires parameter"
      wrongUsageMessage
      exit 1
      ;;

    h | H)
      wrongUsageMessage
      exit 0
      ;;

    \?)
      echo "$OPTARG is unknown parameter"
      wrongUsageMessage
      exit 1
      ;;

    esac
done

if [ "$local" == "" ] || [ "$remote" == "" ] || [ "$archiveDays" == "" ]; then
  echo "Some options are not available"
  wrongUsageMessage
  exit 1
fi

if [ ${local: -1} != "/" ]; then
  local+="/"
fi

if [ ${remote: -1} != "/" ]; then
  remote+="/"
fi
}


############


processCommandLineParameters "$@"

clear

echo ""

echo -e "${BRed}Welcome to Sync Tool${RCol}"
echo -e "${BRed}____________________${RCol}"

echo ""
echo ""
echo -e "${Yel}The information givan by you is as below${RCol}"
echo -en "${Blu}Local Path  :${RCol}"
echo -e "${BRed}$local${RCol}"
echo -en "${Blu}Remote Path :${RCol}"
echo -e "${BRed}$remote${RCol}"
echo -en "${Blu}Archive days :${RCol}"
echo -e "${BRed}$archiveDays${RCol}"
echo -en "${Blu}Local archive path :${RCol}"
echo -e "${BRed}$localArchivePath${RCol}"
echo -en "${Blu}Remote archive path :${RCol}"
echo -e "${BRed}$remoteArchivePath${RCol}"

echo ""
echo ""
echo -ne "${Yel}Are you sure to countinue (y/n) :${RCol}"
read

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if [ ! -d "$local" ]; then
  error "$local path does not exist."
fi

#echo -en "${Yel}\nEnter the IP address of remote server :${RCol}"
#read remoteIP

if (ssh $remoteUserName@$remoteIP "[ ! -d \"$remote\" ]")
then
  error "$remote directory not found on server"
fi

mkdir -p temp

archiveOldFiles

ls -l "$local" | tail -n +2 | awk '{
printf "%s %s %s ",$6,$7,$8 > "temp/local";

for(i=9;i<=NF;++i)
  {
    if(i==NF)
      print $i > "temp/local"
    else
      printf "%s ",$i   > "temp/local"
  }
}'

ssh $remoteUserName@$remoteIP "ls -l \"$remote\"" | tail -n +2 | awk '{
printf "%s %s %s ",$6,$7,$8 > "temp/remote";

for(i=9;i<=NF;++i)
  {
    if(i==NF)
      print $i > "temp/remote"
    else
      printf "%s ",$i   > "temp/remote"
  }
}'

if [ -f "temp/local" ] && [ -f "temp/remote" ]
then
  diff temp/local temp/remote | grep '<' | awk '
  {
    for(i=5;i<=NF;++i)
    {
      if(i==NF)
        print $i
      else
        printf "%s ",$i
    }
  }' | sed "s@^@$local@" | sed -e "s/^/\"/;s/$/\"/" | xargs rm -f

  diff temp/local temp/remote | grep '>' | awk '
  {
    for(i=5;i<=NF;++i)
    {
      if(i==NF)
        print $i
      else
        printf "%s ",$i
    }
  }' | sed -e "s@^@$remoteIP:\"'$remote@;s/$/'\"/" | sed s/^/@/ | sed -e "s@^@$remoteUserName@" | xargs -i{} scp -p {} "$local"

elif [ -f "temp/local" ]
 then
  rm -rf "$local"/*

elif [ -f "temp/remote" ]
 then
  cat temp/remote | awk '
  {
    for(i=4;i<=NF;++i)
    {
      if(i==NF)
        print $i
      else
        printf "%s ",$i
    }
  }' | sed -e "s@^@$remoteIP:\"'$remote@;s/$/'\"/" | sed s/^/@/ | sed -e "s@^@$remoteUserName@" | xargs -i{} scp -p {} "$local"
fi

rm -rf temp
