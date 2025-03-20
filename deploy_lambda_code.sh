#!/bin/bash

BUCKET_NAME="api-gateway-assessment-lambda-code"
REGION="ca-central-1"

# AWS CLI should be installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed. Please install it first."
  exit 1
fi

# User should be logged in to AWS
if ! aws sts get-caller-identity &> /dev/null; then
  echo "Error: You are not logged in to AWS. Please configure AWS CLI credentials."
  exit 1
fi

# Creating S3 bucket if it doesn't exist
if ! aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" &> /dev/null; then
  echo "Creating S3 bucket s3://$BUCKET_NAME in region $REGION..."
  if ! aws s3 mb "s3://$BUCKET_NAME" --region "$REGION" > /dev/null; then
    echo "Error: Failed to create S3 bucket."
    exit 1
  fi
  echo "successfully created bucket"
fi

# Function to package and upload Lambda code
package_and_upload() {
  local lambda_dir=$1
  local zip_file=$2
  local original_dir=$(pwd)

  echo "Packaging $lambda_dir into $zip_file..."

  # Clean any previous zip file
  rm -f "$zip_file"

  # Go to Lambda directory
  cd "$lambda_dir" || { echo "Error: Directory $lambda_dir not found"; exit 1; }

  # Check if this is a Node.js project with package.json
  if [ -f "package.json" ]; then
    echo "Node.js project detected. Installing dependencies..."
    if ! npm install --production; then
      echo "Error: Failed to install Node.js dependencies."
      cd "$original_dir" || exit
      exit 1
    fi
  fi

  zip -r "$original_dir/$zip_file" . > /dev/null

  cd "$original_dir" || exit

  # Uploading to S3
  echo "Uploading $zip_file to S3 bucket..."
  if aws s3 cp "$zip_file" "s3://$BUCKET_NAME/" --region "$REGION" > /dev/null; then
    echo "Successfully uploaded $zip_file"
  else
    echo "Failed to upload $zip_file"
    exit 1
  fi
}

package_and_upload "lambdas/lambda1" "lambdas_lambda1.zip"
package_and_upload "lambdas/lambda2" "lambdas_lambda2.zip"
