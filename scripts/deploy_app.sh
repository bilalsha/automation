#!/usr/bin/env bash

#!/bin/bash

clone_projects () {
    echo ""
    cd $1
    echo " Clone commons project "
    git clone https://gitlab.com/gildasdarex/saggie-commons.git -b $2
    echo " Clone security project "
    git clone https://gitlab.com/gildasdarex/saggie-security.git -b $2
    echo " Clone api project "
    git clone https://gitlab.com/gildasdarex/saggie-api.git -b $2
}

build_projects () {
    echo ""
    echo " Create local maven repo "
    mkdir $1/local-maven-repo
    echo " build commons project "
    cd $1/saggie-commons
    gradle clean build publish
    echo " build security project "
    cd $1/saggie-security
    gradle clean build publish
    echo " build api project "
    cd $1/saggie-api
    gradle clean build publish

    echo " Copy saggie api war to $1 "
    cp $1/local-maven-repo/com/saggie/saggie-api/1.0.0-SNAPSHOT/*.war  $1/saggie-api.war
    rm $1/local-maven-repo/com/saggie/saggie-api/1.0.0-SNAPSHOT/*.war
}


owner="darex"
optspec=":-:"
while getopts "$optspec" optchar; do
    case "${OPTARG}" in
      workdir)
        workdir="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
      ;;
      branch)
        branch="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
      ;;
      log.path)
        log_path="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      spring.config.location)
        spring_config_location="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;
      spring.config.name)
        spring_config_name="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
        ;;

    esac
done


clone_projects $workdir $branch
build_projects $workdir

cd $workdir
java -jar -Dlog.path=$log_path saggie-api.war --spring.config.location=$spring_config_location --spring.config.name=$spring_config_name