#!/usr/bin/env sh

COUNTER=0;
# /app/samvera/hyrax-webapp/solr/conf
CONFDIR="${1}"

if [ "$SOLR_ADMIN_USER" ]; then
  solr_user_settings="--user $SOLR_ADMIN_USER:$SOLR_ADMIN_PASSWORD"
fi

# Solr Cloud ConfigSet API URLs
solr_config_list_url="http://$SOLR_HOST:$SOLR_PORT/api/cluster/configs?omitHeader=true"
solr_config_upload_url="http://$SOLR_HOST:$SOLR_PORT/solr/admin/configs?action=UPLOAD&name=$SOLR_CONFIGSET_NAME"

while [ $COUNTER -lt 30 ]; do
  echo "-- Looking for Solr (${SOLR_HOST}:${SOLR_PORT})..."
  if nc -z "${SOLR_HOST}" "${SOLR_PORT}"; then
    # shellcheck disable=SC2143,SC2086
    if curl --silent --user 'fake:fake' "$solr_config_list_url" | grep -q '401'; then
      # the solr pods come up and report available before they are ready to accept trusted configs
      # only try to upload the config if auth is on.
      if curl --silent $solr_user_settings "$solr_config_list_url" | grep -q "$SOLR_CONFIGSET_NAME"; then
        echo "-- ConfigSet already exists; skipping creation ...";
      else
        echo "-- ConfigSet for ${CONFDIR} does not exist; creating ..."
        (cd "$CONFDIR" && zip -r - *) | curl -X POST $solr_user_settings --header "Content-Type:application/octet-stream" --data-binary @- "$solr_config_upload_url"
      fi
      exit
    else
      echo "-- Solr at $solr_config_list_url is accepting unauthorized connections; we can't upload a trusted ConfigSet."
      echo "--   It's possible SolrCloud is bootstrapping its configuration, so this process will retry."
      echo "--   see: https://solr.apache.org/guide/8_6/configsets-api.html#configsets-upload"
    fi
  fi
  COUNTER=$(( COUNTER+1 ));
  sleep 5s
done

echo "--- ERROR: failed to create Solr ConfigSet after 5 minutes";
exit 1
