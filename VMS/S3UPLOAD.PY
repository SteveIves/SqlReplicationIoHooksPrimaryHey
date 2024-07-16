
import logging
import boto3
import sys
import os
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError
from botocore.config import Config

# Enable logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
boto3.set_stream_logger(name='botocore')

def create_bucket_if_not_exists(s3_client, bucket_name, region_name):
    """Create an S3 bucket if it does not already exist"""
    try:
        s3_client.head_bucket(Bucket=bucket_name)
    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            try:
                if region_name == 'us-east-1':
                    s3_client.create_bucket(Bucket=bucket_name)
                else:
                    s3_client.create_bucket(
                        Bucket=bucket_name,
                        CreateBucketConfiguration={'LocationConstraint': region_name}
                    )
            except ClientError as create_error:
                logger.error(f"Unable to create bucket {bucket_name}. {create_error}")
                return False
        else:
            logger.error(f"Error checking bucket {bucket_name}: {e}")
            return False
    return True

def multipart_upload_to_s3(file_name):
    """Upload a file to an S3 bucket using multipart upload"""

    aws_access_key_id = 'YOUR_AWS_ACCESS_KEY_ID'
    aws_secret_access_key = 'YOUR_AWS_SECRET_ACCESS_KEY'
    region_name = 'us-east-1'
    endpoint_url = 'http://10.1.10.243:8333'
    bucket_name = 'upload'
    part_size=5*1024*1024

    config = Config(
        retries = {
            'max_attempts': 10,
            'mode': 'standard'
        }
    )

    s3_client = boto3.client(
        's3',
        aws_access_key_id=aws_access_key_id,
        aws_secret_access_key=aws_secret_access_key,
        region_name=region_name,
        endpoint_url=endpoint_url,
        config=config
    )

    if not create_bucket_if_not_exists(s3_client, bucket_name, region_name):
        return False

    try:
        # Initiate multipart upload
        response = s3_client.create_multipart_upload(Bucket=bucket_name, Key=file_name)
        upload_id = response['UploadId']

        parts = []
        part_number = 1
        with open(file_name, 'rb') as file:
            while True:
                data = file.read(part_size)
                if not data:
                    break
                part_response = s3_client.upload_part(
                    Bucket=bucket_name,
                    Key=file_name,
                    PartNumber=part_number,
                    UploadId=upload_id,
                    Body=data
                )
                parts.append({
                    'PartNumber': part_number,
                    'ETag': part_response['ETag']
                })
                part_number += 1

        # Complete multipart upload
        s3_client.complete_multipart_upload(
            Bucket=bucket_name,
            Key=file_name,
            UploadId=upload_id,
            MultipartUpload={'Parts': parts}
        )
        return True
    except FileNotFoundError:
        logger.error(f"ERROR: The file {file_name} was not found.")
        return False
    except NoCredentialsError:
        logger.error("ERROR: Credentials not available.")
        return False
    except PartialCredentialsError as e:
        logger.error(f"ERROR: Partial credentials provided. {e}")
        return False
    except ClientError as e:
        logger.error(f"ERROR: Client error: {e}")
        return False

def main():
    if len(sys.argv) != 2:
        print("Usage: python upload_to_s3.py <file_name>")
        sys.exit(1)

    file_name = sys.argv[1]

    success = multipart_upload_to_s3(file_name)
    if success:
        print("SUCCESS")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
