FROM cloudposse/terraform-root-modules:0.41.0 as terraform-root-modules

FROM cloudposse/geodesic:0.46.0

ENV DOCKER_IMAGE="cloudposse/root.cloudposse.co"
ENV DOCKER_TAG="latest"

# Geodesic banner
ENV BANNER="root.cloudposse.co"

# AWS Region
ENV AWS_REGION="us-west-2"
ENV AWS_DEFAULT_REGION="${AWS_REGION}"
ENV AWS_ACCOUNT_ID="323330167063"
ENV AWS_ROOT_ACCOUNT_ID="${AWS_ACCOUNT_ID}"

# Terraform vars
ENV TF_VAR_region="${AWS_REGION}"
ENV TF_VAR_account_id="${AWS_ACCOUNT_ID}"
ENV TF_VAR_namespace="cpco"
ENV TF_VAR_stage="root"

ENV TF_VAR_parent_domain_name="cloudposse.co"
ENV TF_VAR_root_domain_name="root.cloudposse.co"

# Terraform state bucket and DynamoDB table for state locking
ENV TF_BUCKET_REGION="${AWS_REGION}"
ENV TF_BUCKET="${TF_VAR_namespace}-${TF_VAR_stage}-terraform-state"
ENV TF_DYNAMODB_TABLE="${TF_VAR_namespace}-${TF_VAR_stage}-terraform-state-lock"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="${TF_VAR_namespace}-${TF_VAR_stage}-admin"

# chamber KMS config
ENV CHAMBER_KMS_KEY_ALIAS="alias/${TF_VAR_namespace}-${TF_VAR_stage}-chamber"

# Copy root modules
COPY --from=terraform-root-modules /aws/tfstate-backend/ /conf/tfstate-backend/
COPY --from=terraform-root-modules /aws/root-dns/ /conf/root-dns/
COPY --from=terraform-root-modules /aws/organization/ /conf/organization/
COPY --from=terraform-root-modules /aws/accounts/ /conf/accounts/
COPY --from=terraform-root-modules /aws/account-settings/ /conf/account-settings/
COPY --from=terraform-root-modules /aws/root-iam/ /conf/root-iam/
COPY --from=terraform-root-modules /aws/iam/ /conf/iam/
COPY --from=terraform-root-modules /aws/cloudtrail/ /conf/cloudtrail/

# Place configuration in 'conf/' directory
COPY conf/ /conf/

# Install configuration dependencies
RUN make -C /conf install

# Filesystem entry for tfstate
RUN s3 fstab '${TF_BUCKET}' '/' '/secrets/tf'

WORKDIR /conf/
