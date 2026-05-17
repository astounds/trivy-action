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

if ! echo "$VERSION" | grep -qE '^v?[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Invalid version format: $VERSION" >&2
  exit 1
fi

echo "Installing Trivy $VERSION..."

VERSION_NUM="${VERSION#v}"

case "$(uname -m)" in
  x86_64|amd64) ARCH="64bit" ;;
  aarch64|arm64) ARCH="ARM64" ;;
  armv7l|arm)    ARCH="ARM" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

OS="Linux"
ASSET_PREFIX="trivy_${VERSION_NUM}"
GH_BASE="https://github.com/aquasecurity/trivy/releases/download/$VERSION"
TARBALL="${ASSET_PREFIX}_${OS}-${ARCH}.tar.gz"
CHECKSUMS="${ASSET_PREFIX}_checksums.txt"
CHECKSUMS_SIG="${CHECKSUMS}.sigstore.json"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

echo "Downloading checksums..."
curl -sfLO "$GH_BASE/$CHECKSUMS"
curl -sfLO "$GH_BASE/$CHECKSUMS_SIG"

echo "Verifying checksums signature (Cosign/Sigstore)..."
CERT_PEM="$WORK_DIR/cert.pem"
SIG_B64="$WORK_DIR/sig.b64"
jq -r '.verificationMaterial.certificate.rawBytes' "$CHECKSUMS_SIG" | fold -w 64 | {
  echo "-----BEGIN CERTIFICATE-----"
  cat
  echo "-----END CERTIFICATE-----"
} > "$CERT_PEM"
jq -r '.messageSignature.signature' "$CHECKSUMS_SIG" > "$SIG_B64"
cosign verify-blob "$CHECKSUMS" \
  --certificate "$CERT_PEM" \
  --signature "$SIG_B64" \
  --certificate-identity-regexp 'https://github[.]com/aquasecurity/trivy/[.]github/workflows/.+' \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"

echo "Downloading Trivy binary..."
curl -sfLO "$GH_BASE/$TARBALL"

echo "Verifying SHA-256 checksum..."
grep -F "$TARBALL" "$CHECKSUMS" | sha256sum -c -

echo "Extracting Trivy..."
tar xzf "$TARBALL"
cp trivy /usr/local/bin/trivy
chmod 755 /usr/local/bin/trivy

echo "Trivy successfully installed."

TRIVY_CMD=(
  trivy image "$IMAGE"
  --format "$FORMAT"
  --db-repository "$DB_REPOSITORY"
  --java-db-repository "$JAVA_DB_REPOSITORY"
  --exit-code "$EXIT_CODE"
  --pkg-types "$PKG_TYPES"
  --severity "$SEVERITY"
)

if [ "$IGNORE_UNFIXED" == "true" ]; then
  TRIVY_CMD+=(--ignore-unfixed)
fi

echo "Executing command:"
echo "${TRIVY_CMD[*]}"

"${TRIVY_CMD[@]}"
SCAN_RESULT=$?

exit $SCAN_RESULT
