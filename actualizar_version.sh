#! /bin/bash

version=$1
sed -i "s/VERSION=\(.*\)/VERSION=$version/g" "/opt/unitech/conicet/composes/tramix-lh-ui/.env"
