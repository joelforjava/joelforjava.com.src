title=Using AssumeRole with the AWS Java SDK
date=2019-11-27
type=post
tags=aws,java
status=draft
~~~~~~

When working in AWS, AssumeRole allows you to have access to resources to which you might not normally have access. Some use cases for using AssumeRole is for cross-account access, or in my case, developing locally. Using AssumeRole lets me grant my local code permissions as per those provided by the role to which you're assuming, such as DynamoDB, RedShift, or S3 access.

When I first found myself needing to this, I found several tutorials in the AWS documentation that showcased several types of credential usages, such as [federated credentials](https://docs.aws.amazon.com/AmazonS3/latest/dev/AuthUsingTempFederationTokenJava.html) and [temporary credentials](https://docs.aws.amazon.com/AmazonS3/latest/dev/AuthUsingTempSessionTokenJava.html). but I never found a similar tutorial for using AssumeRole. I assume the documentation exists, I just didn't find it in the time I had to work on my code. So, here's how I went about implementing AssumeRole in Java using version `1.11.622`.

<?prettify?>

    private static AWSCredentialsProvider loadCredentials(boolean isLocal) {
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

This is the code I tend to use when having to switch between local development and then deploying to Lambda or to an EC2 Container. The `isLocal` parameter is set to false via an environment variable when deployed. You could remove the `isLocal` check if you're doing something like assuming the role of another account. I created a [gist](https://gist.github.com/joelforjava/cc460b733f684a1e4d1b69d21fd0cd25) that shows it used in the context of a more complete application.

Even though the Kafka-Kinesis Connector is still based on version 1.x of the AWS SDK, I've been trying to incorporate more of the version 2.x SDK into anything new I write. That means the code above won't be of much help. So, I created an updated version, this time using version `2.7.36`.

<?prettify?>

    private static AwsCredentialsProvider loadCredentialsV2() throws ExecutionException, InterruptedException {
        ProfileCredentialsProvider devProfile = ProfileCredentialsProvider.builder()
                .profileName("devjump")
                .build();

        StsAsyncClient stsAsyncClient = StsAsyncClient.builder()
                .credentialsProvider(devProfile)
                .region(Region.US_EAST_1)
                .build();

        AssumeRoleRequest assumeRoleRequest = AssumeRoleRequest.builder()
                .durationSeconds(3600)
                .roleArn("arn:aws:iam::1234567890987:role/Super-Important-Role")
                .roleSessionName("CloudWatch2_Session")
                .build();

        Future<AssumeRoleResponse> responseFuture = stsAsyncClient.assumeRole(assumeRoleRequest);
        AssumeRoleResponse response = responseFuture.get();
        Credentials creds = response.credentials();

        AwsSessionCredentials sessionCredentials = AwsSessionCredentials.create(creds.accessKeyId(), creds.secretAccessKey(), creds.sessionToken());
        return AwsCredentialsProviderChain.builder()
                .credentialsProviders(StaticCredentialsProvider.create(sessionCredentials))
                .build();
    }

In many ways, the code using version 2.x looks like the version 1.x code, except for the fact that we're using classes from the `software.amazon.awssdk.*` packages and a few differences in class names. The process is the same, though. Create an STS client, make the `AssumeRole` request, get the credentials, and then return the credentials provider. If you're having to maintain a project that makes use of both version 1.x and 2.x code, pay special attention to the package names in use! It's very easy to mix up code versions when letting the IDE create your import statements.

I hope this has been of some help to you! I'll try to write more articles about AWS in the future. 