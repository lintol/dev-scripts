#!/bin/sh

PIPELINE=19065179
eval $(AWS_PROFILE=default aws ecr get-login | sed 's/-e none //g')
docker pull 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:artisan-$PIPELINE
docker pull 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:nginx-$PIPELINE
docker pull 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:phpfpm-$PIPELINE

eval $(AWS_PROFILE=lintol aws ecr get-login | sed 's/-e none //g')
docker tag 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:artisan-$PIPELINE 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:artisan-$PIPELINE
docker tag 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:nginx-$PIPELINE 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:nginx-$PIPELINE
docker tag 036345629021.dkr.ecr.eu-west-1.amazonaws.com/lintol:phpfpm-$PIPELINE 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:phpfpm-$PIPELINE
docker push 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:artisan-$PIPELINE
docker push 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:nginx-$PIPELINE
docker push 981938718983.dkr.ecr.eu-west-2.amazonaws.com/lintol/capstone:phpfpm-$PIPELINE
