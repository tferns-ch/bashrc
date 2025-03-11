create_command "aws_auth" "Authenticate with AWS SSO and ECR [--skip-sso]" _aws_auth_impl "$@"
_aws_auth_impl() {
    echo "Authenticating with AWS..."
    [[ "$1" == "--skip-sso" ]] || aws sso login --sso-session "$CH_AWS_SSO_SESSION"
    for region in "${CH_AWS_REGIONS[@]}"; do
        echo "Processing region: $region"
        for account in "${CH_AWS_ACCOUNTS[@]}"; do
            echo "Logging into ECR: $account ($region)"
            aws ecr get-login-password --region "$region" --profile "$CH_AWS_PROFILE" | \
                docker login --username AWS --password-stdin "$account.dkr.ecr.$region.amazonaws.com"
        done
    done
}
