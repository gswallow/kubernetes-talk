#!/bin/bash -x

export org=${org:-gregonaws}
export tld=${tld:-net}
export environment=${environment:-demo}

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-XXX}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-XXX}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-2}
export AWS_REGION=${AWS_REGION:-us-east-2}

export KOPS_STATE_STORE=s3://${org}-kops-state-store
export public_domain=${org}.${tld}
export private_domain=${environment}.${org}
export vpc_cidr_prefix=29
