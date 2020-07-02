# Deploying a Flask API

This is the project starter repo for the fourth course in the [Udacity Full Stack Nanodegree](https://www.udacity.com/course/full-stack-web-developer-nanodegree--nd004): Server Deployment, Containerization, and Testing.

In this project you will containerize and deploy a Flask API to a Kubernetes cluster using Docker, AWS EKS, CodePipeline, and CodeBuild.

The Flask app that will be used for this project consists of a simple API with three endpoints:

- `GET '/'`: This is a simple health check, which returns the response 'Healthy'. 
- `POST '/auth'`: This takes a email and password as json arguments and returns a JWT based on a custom secret.
- `GET '/contents'`: This requires a valid JWT, and returns the un-encrpyted contents of that token. 

The app relies on a secret set as the environment variable `JWT_SECRET` to produce a JWT. The built-in Flask server is adequate for local development, but not production, so you will be using the production-ready [Gunicorn](https://gunicorn.org/) server when deploying the app.

## Initial setup
1. Fork this project to your Github account.
2. Locally clone your forked version to begin working on the project.

## Dependencies

- Docker Engine
    - Installation instructions for all OSes can be found [here](https://docs.docker.com/install/).
    - For Mac users, if you have no previous Docker Toolbox installation, you can install Docker Desktop for Mac. If you already have a Docker Toolbox installation, please read [this](https://docs.docker.com/docker-for-mac/docker-toolbox/) before installing.
 - AWS Account
     - You can create an AWS account by signing up [here](https://aws.amazon.com/#).
     
## Project Steps

Completing the project involves several steps:

1. Write a Dockerfile for a simple Flask API
2. Build and test the container locally
3. Create an EKS cluster
4. Store a secret using AWS Parameter Store
5. Create a CodePipeline pipeline triggered by GitHub checkins
6. Create a CodeBuild stage which will build, test, and deploy your code

For more detail about each of these steps, see the project lesson [here](https://classroom.udacity.com/nanodegrees/nd004/parts/1d842ebf-5b10-4749-9e5e-ef28fe98f173/modules/ac13842f-c841-4c1a-b284-b47899f4613d/lessons/becb2dac-c108-4143-8f6c-11b30413e28d/concepts/092cdb35-28f7-4145-b6e6-6278b8dd7527).


# Virtual Enviornment

We recommend working within a virtual environment whenever using Python for projects. This keeps your dependencies for each project separate and organaized. Instructions for setting up a virual enviornment for your platform can be found in the [python docs](https://packaging.python.org/guides/installing-using-pip-and-virtual-environments/)

On Windows, run the following:
    py -m pip install --user virtualenv
    py -m venv env
The last variable above is the name of the virtual environment.  In this case 'env'
Then add the env folder to the gitignore
Then activate the virtual environment by running:
    .\env\Scripts\activate
If the above doesn't work, use:
    source env/Scripts/activate
Check to see if its running, run:
    where python
It should display something allong the lines of (...env\Scripts\python.exe) if it's running.
To leave the virtual environment, run:
    deactivate

# Notes
Will need to install jq (a JSON parser)
To do this in Windows, run the follwing in an admin shell:
choco install jq

To run, use python main.py
Will need variables avaialble to the terminal, so run the following:
    export JWT_SECRET='myjwtsecret'
    export LOG_LEVEL=DEBUG
    export TOKEN=`curl -d '{"email":"test@test.com","password":"nopassword"}' -H "Content-Type: application/json" -X POST localhost:8080/auth  | jq -r '.token'`

The last variable is the authorization token.  Calls the endpoint 'localhost:8080/auth' with the 
{"email":"<EMAIL>","password":"<PASSWORD>"} as the message body.

To try check the contents of the token, use:
curl --request GET 'http://127.0.0.1:8080/contents' -H "Authorization: Bearer ${TOKEN}" | jq .

Create the docker file and run it using the notes in the file

Once the dockerfile is running try the endpoints using the following
export TOKEN=`curl -d '{"email":"test@test.com","password":"password"}' -H "Content-Type: application/json" -X POST localhost:80/auth  | jq -r '.token'`

curl --request GET 'http://127.0.0.1:80/contents' -H "Authorization: Bearer ${TOKEN}" | jq .

Create a Kubernetes (EKS) Cluster
eksctl create cluster --name simple-jwt-api
To check the process, go to https://us-east-1.console.aws.amazon.com/cloudformation/ and make sure you're in the correct zone

The AWS AIM's can be found here: https://console.aws.amazon.com/iam/home#/users


Greate an environment variable for the account id via:
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

Create a role policy that allows the actions eks:describe via:
TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

Create a role
aws iam create-role --role-name UdacityFlaskDeployCBKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

Create a role policy document via:
echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": [ "eks:Describe*", "ssm:GetParameters" ], "Resource": "*" } ] }' > 'tmp/iam-role-policy'

Attach the policy to the 'UdacityFlaskDeployCBKubectlRole' via:
aws iam put-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe --policy-document file://./tmp/iam-role-policy



Get the current configmap and save it to a file
kubectl get -n kube-system configmap/aws-auth -o yaml > ./aws-auth-patch.yml 

In the data/mapRoles section of this document add, replacing ACCOUNT_ID with your account id:
  - groups:
      - system:masters
      rolearn: arn:aws:iam::ACCOUNT_ID:role/UdacityFlaskDeployCBKubectlRole
      username: build


Account id can be found via this:
aws sts get-caller-identity

Update your cluster's configmap with:
kubectl patch configmap/aws-auth -n kube-system --patch "$(cat aws-auth-patch.yml)"

Generate a GitHub access token by going here: https://github.com/settings/tokens/
generate the token with full control of private repositories by checking all under repo
See gitHubKey file for the key created.  

Create an environment variable for the key using:
aws ssm put-parameter --name JWT_SECRET --value "secrtetkeyhere" --type SecureString

Create a stack on aws using this link: https://us-east-1.console.aws.amazon.com/cloudformation/

Use the ci-cd-codepipeline.cfn.yml file as template
Make sure all the nessecary defaults are filled in that file

I named the stack HiltzUdacityProject4

Test the endpoints using:
kubectl get services simple-jwt-api -o wide
Shold return something with the name simple-jwt-api
The ip needed for the step below should be under cluster-ip in the return above
Was 'abb379b926bd840369d47671ff093ebe-1809895574.us-east-1.elb.amazonaws.com' in this case

Push an update to the github repository, then check the following site to see if it took:
https://console.aws.amazon.com/codesuite/codepipeline/pipelines?region=us-east-1

Use the external ip url to test the app, replacing the variables:
export TOKEN=`curl -d '{"email":"test@email.com","password":"thisPassword"}' -H "Content-Type: application/json" -X POST abb379b926bd840369d47671ff093ebe-1809895574.us-east-1.elb.amazonaws.com/auth  | jq -r '.token'`
curl --request GET 'abb379b926bd840369d47671ff093ebe-1809895574.us-east-1.elb.amazonaws.com/contents' -H "Authorization: Bearer ${TOKEN}" | jq 


To delete the cluster use:
eksctl delete cluster simple-jwt-api

Or manually delete it in the aws GUI

Delete the stack as well





