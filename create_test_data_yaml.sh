ENVIRONMENT_ARN=$(aws proton get-environment \
      --name "multi-svc-beta" \
      --region ${AWS_REGION} | \
    jq -r '.environment.arn');
RAW_OUTPUTS=$(aws cloudformation describe-stacks --region ${AWS_REGION} | \
    jq --arg env_arn "$ENVIRONMENT_ARN" -r '.Stacks[] | 
      select( .Tags[].Value | contains($env_arn)) | .Outputs');
OUTPUTS=$(echo $RAW_OUTPUTS |  yq e -P - | \
  sed -r -e 's/OutputKey/key/g' -e 's/OutputValue/value/g' | \
  yq e ' . | from_entries' - | \
  sed 's/^/      /');
cat <<EOF > ./test_data.yaml
---
'./svc-workshop/instance_infrastructure/cloudformation.yaml':
  environment:
    outputs:
$OUTPUTS
  service:
    name: "front-end"
  service_instance:
    name: "front-end-beta"
    environment: "multi-svc-beta"
    inputs:
      port: 3000
      desired_count: 1
      task_size: medium
      scope: public
      env_vars: >
        CRYSTAL_URL=http://crystal.protonworkshop.hosted.local:3000/crystal;
        NODEJS_URL=http://nodejs.protonworkshop.hosted.local:3000
EOF
cat <<EOF > ./requirements.txt
yamllint
jinja2
EOF

cat <<EOF > ./venv.sh
#!/usr/bin/env bash
virtualenv venv
. venv/bin/activate
pip install -r requirements.txt
EOF
