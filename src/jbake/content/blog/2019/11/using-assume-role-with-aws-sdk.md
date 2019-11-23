title=Using AssumeRole with the AWS Java SDK
date=2019-11-27
type=post
tags=aws,java
status=draft
~~~~~~

When working in AWS, AssumeRole allows you to have access to resources to which you might not normally have access. Some use cases for using AssumeRole is for cross-account access, or in my case, developing locally. Using AssumeRole lets me grant my local code permissions as per those provided by the role to which you're assuming, such as DynamoDB, RedShift, or S3 access.

When I first found myself needing to this, I found several tutorials in the AWS documentation that showcased several types of credential usages, such as [federated credentials](https://docs.aws.amazon.com/AmazonS3/latest/dev/AuthUsingTempFederationTokenJava.html) and [temporary credentials](https://docs.aws.amazon.com/AmazonS3/latest/dev/AuthUsingTempSessionTokenJava.html). but I never found a similar tutorial for using AssumeRole. I assume the documentation exists, I just didn't find it in the time I had to work on my code. So, here's how I went about implementing AssumeRole in Java.

<?prettify?>

    private AWSCredentialsProvider loadCredentials(boolean isLocal) {
        final AWSCredentialsProvider credentialsProvider;
        if (isLocal) {
            AWSSecurityTokenService stsClient = AWSSecurityTokenServiceAsyncClientBuilder.standard()
                    .withCredentials(new ProfileCredentialsProvider("devjump"))
                    .withRegion("us-east-1")
                    .build();

            AssumeRoleRequest assumeRoleRequest = new AssumeRoleRequest().withDurationSeconds(3600)
                    .withRoleArn("arn:aws:iam::1234567890987:role/Super-Important-Role")
                    .withRoleSessionName("CloudWatch_Session");

            AssumeRoleResult assumeRoleResult = stsClient.assumeRole(assumeRoleRequest);
            Credentials creds = assumeRoleResult.getCredentials();

            credentialsProvider = new AWSStaticCredentialsProvider(
                    new BasicSessionCredentials(creds.getAccessKeyId(),
                            creds.getSecretAccessKey(),
                            creds.getSessionToken())
            );
        } else {
            credentialsProvider = new DefaultAWSCredentialsProviderChain();
        }

        return credentialsProvider;
    }

This is the code I tend to use when having to switch between local development and then deploying to Lambda or to an EC2 Container. The `isLocal` parameter is set to false via an environment variable when deployed. You could remove the `isLocal` check if you're doing something like assuming the role of another account.
