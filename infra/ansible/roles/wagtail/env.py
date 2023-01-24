import os
import json
import botocore 
import botocore.session 
from aws_secretsmanager_caching import SecretCache, SecretCacheConfig 

os.environ['AWS_DEFAULT_REGION'] = 'ap-southeast-2'

client = botocore.session.get_session().create_client('secretsmanager')
cache_config = SecretCacheConfig()
cache = SecretCache( config = cache_config, client = client)

secret = cache.get_secret_string('dev/wagtailcms')

db_secret = json.loads(secret)

with open("/var/www/html/.env", "w") as f:
    f.write("DB_PASSWORD=" + db_secret['db_password'] + "\n")
    f.write("DB_USER=" + db_secret['db_username'] + "\n")
    f.write("DB_NAME=" + db_secret['db_name'] + "\n")
    f.write("DB_HOST=" + db_secret['host'] + "\n")
    f.write("DB_PORT=" + db_secret['port'] + "\n")
    f.write("DJANGO_SUPERUSER_USERNAME=" + db_secret['admin'] + "\n")
    f.write("DJANGO_SUPERUSER_EMAIL=" + db_secret['email'] + "\n")
    f.write("DJANGO_SUPERUSER_PASSWORD=" + db_secret['password'] + "\n")
    f.write("SECRET_KEY=" + db_secret['secret'] + "\n")
    f.write("DJANGO_SETTINGS_MODULE=cms.settings.production")
