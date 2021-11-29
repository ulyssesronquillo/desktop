#!/bin/bash

if [ $# -eq 0 ]; then echo 'No user provided.'; exit 1; fi

user=$1
credentials='/home/ulysses/.aws/credentials'-$user
new_key_file='/home/ulysses/new-access-key.json'
old_key_file='/home/ulysses/old-access-key.json'

get-old-credentials () {
	aws iam list-access-keys --user-name $user > $old_key_file
	old_key=$(jq .AccessKeyMetadata[0].AccessKeyId $old_key_file | tr -d \")
}

create-new-key () {
	aws iam create-access-key --user-name $user > $new_key_file
}

get-new-key () {
	new_key=$(jq .AccessKey.AccessKeyId $new_key_file | tr -d \")
	new_secret=$(jq .AccessKey.SecretAccessKey $new_key_file | tr -d \")
}

backup-old-credentials () {
	cp /home/ulysses/.aws/credentials /home/ulysses/.aws/credentials-backup
}

store-new-key () {
	if [ $user == 'ulysses' ]; then
  		echo '[default]' > $credentials
		echo 'aws_access_key_id = ' $new_key >> $credentials
		echo 'aws_secret_access_key = ' $new_secret >> $credentials
	elif [ $user == 'tfc' ]; then
		echo '[tfc]' > $credentials
		echo 'aws_access_key_id = ' $new_key >> $credentials
		echo 'aws_secret_access_key = ' $new_secret >> $credentials
	else
		echo 'do nothing'
	fi
}

combine-credentials () {
	cat /home/ulysses/.aws/credentials-ulysses /home/ulysses/.aws/credentials-tfc > /home/ulysses/.aws/credentials
}

delete-old-key () {
        sleep 10s
	aws iam delete-access-key --user-name $user --access-key-id $old_key
}

cleanup () {
	rm $new_key_file
	rm $old_key_file
}

get-old-credentials
create-new-key
get-new-key
backup-old-credentials
store-new-key
combine-credentials
delete-old-key

