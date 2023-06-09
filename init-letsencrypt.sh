#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

domains=(example.com)
rsa_key_size=4096
data_path="./certbot"
email="parth@example.com" # Adding a valid address is strongly recommended
staging=1 # Set to 1 if you're testing your setup to avoid hitting request limits

# if [ -d "$data_path" ]; then
#   read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
#   if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
#     exit
#   fi
# fi


# if [ ! -e "$data_path/conf/options-ssl-nginx.conf" ] || [ ! -e "$data_path/conf/ssl-dhparams.pem" ]; then
#   echo "### Downloading recommended TLS parameters ..."
#   mkdir -p "$data_path/conf"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$data_path/conf/options-ssl-nginx.conf"
#   curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$data_path/conf/ssl-dhparams.pem"
#   echo
# fi


#functin to check certificate expiry
function check_cert()
{
  if [ -d "./certbot/" ] ; then
    TARGET="tradekit.pro"; 
    RECIPIENT="hostmaster@mysite.example.net";
    DAYS=7;
    echo "checking if $TARGET expires in less than $DAYS days";
    expirationdate=$(date -d "$(: | openssl s_client -connect $TARGET:443 -servername $TARGET 2>/dev/null \
                                | openssl x509 -text \
                                | grep 'Not After' \
                                |awk '{print $4,$5,$7}')" '+%s'); 
    in7days=$(($(date +%s) + (86400*$DAYS)));
    if [ $in7days -gt $expirationdate ]; then
        # echo "KO - Certificate for $TARGET expires in less than $DAYS days, on $(date -d @$expirationdate '+%Y-%m-%d')" \
        # | mail -s "Certificate expiration warning for $TARGET" $RECIPIENT ;
        RETURN_THIS="EXPIRED"
        echo $RETURN_THIS
        return
    else
        # echo "OK - Certificate expires on $expirationdate";
        RETURN_THIS="NOT_EXPIRED"
        echo $RETURN_THIS
        return
    fi;
  else
    RETURN_THIS="NOT_PRESENT"
    echo $RETURN_THIS
    return
  fi
}



echo "### Starting web application ..."
docker-compose up --force-recreate -d nodeserver

CERTIFICATE=$(check_cert)
if [[ "$CERTIFICATE" == "EXPIRED" || "$CERTIFICATE" == "NOT_PRESENT" ]]; then

  echo "### Deleting crertbot ..."
  sudo rm -rf ./certbot


  echo "### Creating dummy certificate for $domains ..."
  path="/etc/letsencrypt/live/$domains"
  mkdir -p "$data_path/conf/live/$domains"
  docker-compose run --rm --entrypoint "\
    openssl req -x509 -nodes -newkey rsa:$rsa_key_size -days 1\
      -keyout '$path/privkey.pem' \
      -out '$path/fullchain.pem' \
      -subj '/CN=localhost'" certbot
  echo

  echo "### Starting nginx ..."
  docker-compose up --force-recreate -d nginx
  echo

  echo "### Deleting dummy certificate for $domains ..."
  docker-compose run --rm --entrypoint "\
    rm -Rf /etc/letsencrypt/live/$domains && \
    rm -Rf /etc/letsencrypt/archive/$domains && \
    rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
  echo


  echo "### Requesting Let's Encrypt certificate for $domains ..."
  #Join $domains to -d args
  domain_args=""
  for domain in "${domains[@]}"; do
    domain_args="$domain_args -d $domain"
  done

  # Select appropriate email arg
  email_arg="--email $email"

  # Enable staging mode if needed
  if [ $staging != "0" ]; then staging_arg="--staging"; fi

  docker-compose run --rm --entrypoint "\
    certbot certonly --webroot -w /var/www/certbot \
      $email_arg \
      $staging_arg \
      $domain_args \
      --rsa-key-size $rsa_key_size \
      --non-interactive \
      --agree-tos \
      --force-renewal" certbot
  echo

  echo "### Reloading nginx ..."
  docker-compose exec nginx nginx -s reload
else
  echo "Certificate not expired"
fi


