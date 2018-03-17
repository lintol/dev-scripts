#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh

echo
echo
echo "INSTALLING CKAN..."
echo

git clone https://github.com/ckan/ckan.git ckan
(cd ckan && git checkout -b release-v2.6-latest)

 docker build --build-arg CKAN_SITE_URL=${CKAN_SITE_URL} -t ckan_local ckan
docker-compose -f docker-compose.ckan.yml up &
sleep 10
docker-compose -f docker-compose.ckan.yml stop

docker-compose -f docker-compose.ckan.yml up &
sleep 10
docker-compose -f docker-compose.ckan.yml stop
# Need to do this this many times to get all creation/editing done before mounting volumes (=> perm errors)


sudo apt-get install -y jq

export VOL_PREFIX=$(basename $(pwd))

# Find the path to a named volume
docker volume inspect ${VOL_PREFIX}_ckan_home | jq -c '.[] | .Mountpoint'
# "/var/lib/docker/volumes/docker_ckan_config/_data"

export VOL_CKAN_HOME=`docker volume inspect ${VOL_PREFIX}_ckan_home | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_HOME

export VOL_CKAN_CONFIG=`docker volume inspect ${VOL_PREFIX}_ckan_config | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_CONFIG

export VOL_CKAN_STORAGE=`docker volume inspect ${VOL_PREFIX}_ckan_storage | jq -r -c '.[] | .Mountpoint'`
echo $VOL_CKAN_STORAGE

sudo apt-get install -y bindfs
mkdir ./ckan-home ./ckan-config
sudo chown -R `whoami`:docker $VOL_CKAN_HOME
sudo bindfs --map=900/`whoami` $VOL_CKAN_HOME ./ckan-home
sudo chown -R `whoami`:docker $VOL_CKAN_CONFIG
sudo bindfs --map=900/`whoami` $VOL_CKAN_CONFIG ./ckan-config

NEW_PLUGINS="datastore datapusher validation oauth2provider scheming_datasets"
CKAN_INI=./ckan-config/production.ini

docker-compose -f docker-compose.ckan.yml up &
sleep 5

docker exec -it ckan_db psql -U ckan -f 00_create_datastore.sql
docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i ckan_db psql -U ckan

echo "
source \$CKAN_VENV/bin/activate && cd \$CKAN_VENV/src/

git clone https://github.com/lintol/ckanext-oauth2provider
cd ckanext-oauth2provider
pip install -r dev-requirements.txt
python setup.py install
python setup.py develop
cd ..

git clone https://github.com/ckan/ckanext-scheming.git
cd ckanext-scheming
pip install -r requirements.txt
python setup.py install
python setup.py develop
cd ..

git clone https://github.com/lintol/ckanext-validation.git
cd ckanext-validation
pip install -r requirements.txt
python setup.py install
python setup.py develop
cd ..

# exit the ckan container:
exit
" | docker exec -u root -i ckan /bin/bash -c "export TERM=xterm; exec bash"

rm -f /tmp/ckan.ini
echo "
ckanext.oauth2provider.secret_key = '$CKAN_OAUTH2_KEY'
scheming.dataset_schemas = ckanext.validation.examples:ckan_default_schema.json
scheming.presets = ckanext.scheming:presets.json
	    ckanext.validation:presets.json
ckanext.validation.run_on_create_async = True
ckanext.validation.run_on_update_async = True
" > /tmp/ckan.ini
sed -i '/ckan.plugins/ r /tmp/ckan.ini' $CKAN_INI

docker exec ckan /usr/local/bin/ckan-paster --plugin=ckanext-validation validation init-db -c /etc/ckan/production.ini

docker-compose -f docker-compose.ckan.yml stop

for plugin in $NEW_PLUGINS
do
    grep "^ckan\.plugins.*$plugin" $CKAN_INI
    if [ $? -ne 0 ]
    then
	sudo sed -i "s/^ckan\.plugins\(.*\)$/ckan.plugins\1 $plugin/g" $CKAN_INI
    fi
done

sudo sed -i "s/#ckan.datapusher.formats/ckan.datapusher.formats/" $CKAN_INI
