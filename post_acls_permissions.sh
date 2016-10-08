#!/bin/bash
# Post a set of ACL permission rules to a running DC/OS cluster, read from a file 
#where they're stored in raw JSON format as received from the accompanying
#"get_acls_permissions.sh" script.

#reference:
#https://docs.mesosphere.com/1.8/administration/id-and-access-mgt/iam-api/#!/permissions/put_acls_rid
#https://docs.mesosphere.com/1.8/administration/id-and-access-mgt/iam-api/#!/permissions/put_acls_rid_users_uid_action

#Load configuration if it exists
#config is stored directly in JSON format in a fixed location
CONFIG_FILE=$PWD"/.config.json"
if [ -f $CONFIG_FILE ]; then
  DCOS_IP=$(cat $CONFIG_FILE | jq -r '.DCOS_IP')
  USERNAME=$(cat $CONFIG_FILE | jq -r '.USERNAME')
  PASSWORD=$(cat $CONFIG_FILE | jq -r '.PASSWORD')
  DEFAULT_USER_PASSWORD=$(cat $CONFIG_FILE | jq -r '.DEFAULT_USER_PASSWORD')
  DEFAULT_USER_SECRET=$(cat $CONFIG_FILE | jq -r '.DEFAULT_USER_SECRET')
  WORKING_DIR=$(cat $CONFIG_FILE | jq -r '.WORKING_DIR')
  CONFIG_FILE=$(cat $CONFIG_FILE | jq -r '.CONFIG_FILE')
  USERS_FILE=$(cat $CONFIG_FILE | jq -r '.USERS_FILE')
  GROUPS_FILE=$(cat $CONFIG_FILE | jq -r '.GROUPS_FILE')
  ACLS_FILE=$(cat $CONFIG_FILE | jq -r '.ACLS_FILE')
  ACLS_PERMISSIONS_FILE=$(cat $CONFIG_FILE | jq -r '.ACLS_PERMISSIONS_FILE')
  ACLS_PERMISSIONS_ACTIONS_FILE=$(cat $CONFIG_FILE | jq -r '.ACLS_PERMISSIONS_ACTIONS_FILE')
else
  echo "** ERROR: Configuration not found. Please run ./run.sh first"
fi

#loop through the list of ACL Permission Rules
jq -r '.array|xs[]' $ACLS_PERMISSIONS_FILE | while read x; do

	echo -e "*** Loading permission "$x" ..."	
	#get this permission
	PERMISSION=$(jq ".array[$x]" $ACLS_PERMISSIONS_FILE)
  	#extract fields
	_PID=$(echo $RULE | jq -r ".rid")
	URL=$(echo $RULE | jq -r ".url")
	DESCRIPTION=$(echo $RULE | jq -r ".description")
	#DEBUG
	echo -e "*** Rule "$x" is: "$_RID

    	#add BODY for this RULE's fields
    	BODY="{ \
"\"description"\": "\"$DESCRIPTION"\",\
}"
	echo -e "** DEBUG: Body *post-rule* "$_RID" is: "$BODY

	#Create this RULE
	echo -e "*** Posting RULE "x": "$_RID" ..."
	RESPONSE=$( curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-d "$BODY" \
-X PUT \
http://$DCOS_IP/acs/api/v1/acls/$_RID )
	sleep 1

	#report result
 	echo "ERROR in creating RULE: "$_RID" was :"
	echo $RESPONSE| jq

	#loop through the list of Users that this Rule is associated to 
	jq -r '.user|ys[]' $RULE | while read y; do

		echo -e "*** Loading user "$y" ..."	
		#get this USER
		USER=$(jq ".array[$y]" $RULE)
		#extract fields. Users are only PATH, no more fields.
		_UID=$(echo $USER | jq -r ".uid")
		#DEBUG
		echo -e "*** User "$y" is: "_UID

		#no BODY -- just PATH
	
		#no need to create this USER either (no body)

		#report result
 		echo "ERROR in creating USER: "$_UID" was :"
		echo $RESPONSE| jq

		#loop through the list of Actions of this User/Rule has
		jq -r '.user|zs[]' $USER | while read z; do

			echo -e "*** Loading action "$z" ..."	
			#get this ACTION
			ACTION=$(jq ".array[$z]" $USER)
			#extract fields
			_AID=$(echo $ACTION | jq ".array[$z]" $ACTION)
    			ALLOWED=$(echo $ACTION | jq -r ".allowed")    	
  			#DEBUG
			echo -e "*** User "$y" is: "_UID

     			#add BODY for this RULE's fields
     			BODY="{ \
"\"allowed"\": "\"$ALLOWED"\",\
}"

			echo -e "** DEBUG: Body *post-action* "$_AID" is: "$BODY
    		
			#Create this ACTION
			echo -e "*** Posting ACTION "$_AID" to USER "_$UID" ..."
			RESPONSE=$( curl \
-H "Content-Type:application/json" \
-H "Authorization: token=$TOKEN" \
-d "$BODY" \
-X PUT \
http://$DCOS_IP/acs/api/v1/acls/_$RID/users/$_UID/$_AID )
			sleep 1

			#report result
 			echo "ERROR in creating ACTION: "$_AID" was :"
			echo $RESPONSE| jq

		#ACTIONS
		done
	#USERS
	done
#****TODO: repeat with groups
#RULES
done

echo "Done."
