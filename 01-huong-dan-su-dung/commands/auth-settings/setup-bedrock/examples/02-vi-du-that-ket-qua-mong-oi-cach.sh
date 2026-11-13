# Máy đã có AWS CLI + SSO org:
aws sso login --profile team-dev
# → browser SSO OK

/setup-bedrock
# → region: ap-southeast-1 [Yes]
# → auth: SSO profile team-dev [Yes]
# → model: sonnet (đã enable) [Yes]
