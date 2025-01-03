import os
import boto3
import json

AWS_ACCOUNT_ID = os.environ.get("AWS_ACCOUNT_ID")
AWS_REGION = os.environ.get("AWS_REGION")
AWS_ACCESS_KEY = os.environ.get("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.environ.get("AWS_SECRET_ACCESS_KEY")
GITHUB_RUN_ID = os.environ.get("GITHUB_RUN_ID")


def main():
    env = get_environment()
    boto3_session = init_boto3_session()
    replace_placeholders(env, boto3_session)
    ecr_repo = "spotify-lambda-images-ecr"
    print(f"::set-output name=ecr_repo_name::{ecr_repo}")


def replace_placeholders(env, boto3_session):
    ecr_repo = "spotify-lambda-images-ecr"
    tfvars_path = "../iac/terraform.tfvars"
    backend_path = "../iac/provider.tf"
    # importing spotify credentials from aws secrets manager 
    spotify_credentials = get_aws_secret("/spotify/credentials", boto3_session)
    client_id = spotify_credentials["client_id"]
    client_secret = spotify_credentials["client_secret"]
    image = f"{AWS_ACCOUNT_ID}.dkr.ecr.{AWS_REGION}.amazonaws.com/{ecr_repo}:{GITHUB_RUN_ID}"

    with open(tfvars_path, "r") as f:
        tfvars = f.read()
    tfvars = tfvars.replace("aws_region_placeholder", str(AWS_REGION))
    tfvars = tfvars.replace("access_key_placeholder", str(AWS_ACCESS_KEY))
    tfvars = tfvars.replace("secret_key_placeholder", str(AWS_SECRET_ACCESS_KEY))
    tfvars = tfvars.replace("env_placeholder", str(env))
    tfvars = tfvars.replace("client_id_placeholder", str(client_id))
    tfvars = tfvars.replace("client_secret_placeholder", str(client_secret))
    tfvars = tfvars.replace("image_uri_placeholder", str(image))
    with open(tfvars_path, "w") as f:
        f.write(tfvars)
    
    with open(backend_path, "r") as f:
        backend_config = f.read()
    backend_config = backend_config.replace("access_key_placeholder", str(AWS_ACCESS_KEY))
    backend_config = backend_config.replace("secret_key_placeholder", str(AWS_SECRET_ACCESS_KEY))
    backend_config = backend_config.replace("aws_region_placeholder", str(AWS_REGION))
    with open(backend_path, "w") as f:
        f.write(backend_config)

def init_boto3_session():
    return boto3.Session(
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION
    )

def get_environment():
    env_name = os.environ.get("GITHUB_BASE_REF", "")
    env_name_parts = env_name.split("/")
    env_name = env_name_parts[-1]

    return env_name

def get_aws_secret(secret_path, session):
    secrets_manager = session.client("secretsmanager")
    response = secrets_manager.get_secret_value(SecretId=secret_path)
    secret = json.loads(response["SecretString"])

    return secret

######### START ##########
if __name__ == "__main__":
    main()

