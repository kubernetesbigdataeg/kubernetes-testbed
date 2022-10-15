# Custom settings
export BINPATH="$HOME/.local/bin"
export SDKVERSION=v1.24.0
# Change above custom settings

echo "==> 01 - Getting architecture/os target platform"
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')
echo -ne "\tArchitecture: $ARCH\n"
echo -ne "\tOS: $OS\n"

echo "==> 02 - Download the binary for your platform"
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/$SDKVERSION
[ ! -f operator-sdk_${OS}_${ARCH} ] && curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}

echo "==> 03 - Verify the downloaded binary"
# Import the operator-sdk release GPG key from keyserver.ubuntu.com
gpg --keyserver keyserver.ubuntu.com --recv-keys 052996E2A20B5C7E
# Download the checksums file and its signature, then verify the signature
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt
curl -LO ${OPERATOR_SDK_DL_URL}/checksums.txt.asc
gpg -u "Operator SDK (release) <cncf-operator-sdk@cncf.io>" --verify checksums.txt.asc
grep operator-sdk_${OS}_${ARCH} checksums.txt | sha256sum -c -
rm checksums.txt checksums.txt.asc

echo "==> 04 - Install the release binary in your PATH"
chmod +x operator-sdk_${OS}_${ARCH} && mv operator-sdk_${OS}_${ARCH} $BINPATH/operator-sdk
echo
echo -ne "\toperator-sdk cli installed at $BINPATH\n"

