#!/bin/bash


owner="darex"
optspec=":-:"
while getopts "$optspec" optchar; do
    case "${OPTARG}" in
      version)
        version="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      wars.dir)
        war_path="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      war.name)
        war_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      app.name)
        app_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      image.name)
        image_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      owner.docker.repos)
        owner="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
    esac
done


docker login $REG_URL
if [ $? -ne 0 ]
then
    echo "Cannot login to registry. Please try again."
    exit 1
fi


rm docker-src/*.war

cp -r $war_path docker-src/.



cmd="docker build --no-cache -t $image_name:v$version \
        --build-arg version=$version \
        --build-arg war=$war_name
        --build-arg app_name=$app_name\
        --file=./Dockerfile ."
$cmd

docker tag $image_name:v$version $owner/$image_name:v$version
docker push $owner/$image_name:v$version

