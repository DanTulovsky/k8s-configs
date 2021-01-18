export IMAGE_NAME="nginx"
export IMAGE_ID="ghcr.io/dantulovsky/k8s-configs/nginx/$IMAGE_NAME"
export VERSION="v1.2.0"

echo "Building local/$IMAGE_NAME"
docker build . --file Dockerfile --tag local/$IMAGE_NAME

echo "Tagging local/$IMAGE_NAME $IMAGE_ID:$VERSION"
docker tag local/$IMAGE_NAME $IMAGE_ID:$VERSION

echo "Pushing $IMAGE_ID:$VERSION"
docker push $IMAGE_ID:$VERSION
