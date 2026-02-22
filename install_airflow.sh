# Create or replace a kind cluster
# kind delete cluster --name kind
# kind create cluster --image kindest/node:v1.29.4

# Add airflow to my Helm repo
# helm repo add apache-airflow https://airflow.apache.org
# helm repo update
# helm show values apache-airflow/airflow > charts/values-example.yaml

# Export values for Airflow docker image
export IMAGE_NAME=airflow-dags
export IMAGE_TAG=$(date +%Y%m%d%H%M%S)
export NAMESPACE=airflow
export RELEASE_NAME=airflow

# Build the image and load it into kind
docker build --pull --tag $IMAGE_NAME:$IMAGE_TAG -f cicd/Dockerfile .
kind load docker-image $IMAGE_NAME:$IMAGE_TAG

# Create a namespace
kubectl create namespace $NAMESPACE

# Apply kubernetes secrets from environment variables
# Required: export GIT_USERNAME=<your-github-username> GIT_PASSWORD=<your-github-token>
kubectl create secret generic git-credentials \
    --namespace $NAMESPACE \
    --from-literal=GITSYNC_USERNAME="$GIT_USERNAME" \
    --from-literal=GITSYNC_PASSWORD="$GIT_PASSWORD" \
    --from-literal=GIT_SYNC_USERNAME="$GIT_USERNAME" \
    --from-literal=GIT_SYNC_PASSWORD="$GIT_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

# Install Airflow using Helm
helm install $RELEASE_NAME apache-airflow/airflow \
    --namespace $NAMESPACE -f charts/values-override.yaml \
    --set-string images.airflow.tag="$IMAGE_TAG" \
    --debug

# Port forward the API server
kubectl port-forward svc/$RELEASE_NAME-api-server 8080:8080 --namespace $NAMESPACE