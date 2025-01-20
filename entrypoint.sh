#!/bin/bash
set -e

VERSION=$1
IMAGE=$2
DB_REPOSITORY=$3
JAVA_DB_REPOSITORY=$4
SEVERITY=$5
EXIT_CODE=$6
IGNORE_UNFIXED=$7
PKG_TYPES=$8
FORMAT=$9

echo "Installing Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin $VERSION
echo "Trivy successfully installed."

TRIVY_CMD="trivy image $IMAGE \
  --format $FORMAT \
  --db-repository $DB_REPOSITORY \
  --java-db-repository $JAVA_DB_REPOSITORY \
  --exit-code $EXIT_CODE \
  --pkg-types $PKG_TYPES \
  --severity $SEVERITY"

if [ "$IGNORE_UNFIXED" == "true" ]; then
  TRIVY_CMD="$TRIVY_CMD --ignore-unfixed"
fi

echo "Executing command:"
echo "$TRIVY_CMD"

$TRIVY_CMD
SCAN_RESULT=$?

exit $SCAN_RESULT
