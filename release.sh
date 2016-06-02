#!/bin/sh

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

BUILD_DIR=./build
NEW_PEAR_CHANNEL=trafficgate.github.io/pirum

GIT_URLS=(
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
    https://github.com/sebastianbergmann/
)

PEAR_CHANNELS=(
    pear.phpunit.de
    pear.phpunit.de
    pear.phpunit.de
    pear.phpunit.de
    pear.phpunit.de
    pear.phpunit.de
    pear.phpunit.de
)

REPOSITORY_NAMES=(
    php-file-iterator
    php-code-coverage
    php-timer
    php-token-stream
    phpunit-mock-objects
    phpunit
    php-text-template
)

PACKAGE_NAMES=(
    File_Iterator
    PHP_CodeCoverage
    PHP_Timer
    PHP_TokenStream
    PHPUnit_MockObject
    PHPUnit
    Text_Template
)

PACKAGE_VERSIONS=(
    1.3.1
    1.1.1
    1.0.2
    1.1.3
    1.1.1
    3.6.12
    1.1.1
)

if [ "${CURRENT_BRANCH}" == 'gh-pages' ]; then
    echo 'Cannot release from gh-pages branch.'
    exit
fi

if ! which pear; then
    echo 'Must have pear available in PATH.'
    exit
fi

# Delete gh-pages if it exists
git branch -D gh-pages

# Create a new gh-pages branch and switch to it.
git checkout -b gh-pages

# We will re-build all the packages from scratch
# So remove files related to the channel
rm -rf channel.xml feed.xml index.html packages.json get/ rest/

# Checkout pirum
if [ -e composer.lock ]; then
    composer install
else
    composer update
fi

# Create the build directory
if [ ! -d "${BUILD_DIR}" ]; then
    mkdir "${BUILD_DIR}"
fi

# Add channel
pear channel-discover ${NEW_PEAR_CHANNEL}

# Build the initial channel information
./vendor/bin/pirum build .

# Download the PEAR package, extract it, alter the channel info, re-package, and add to pirum
pushd "${BUILD_DIR}"
for ((index = 0; index < ${#REPOSITORY_NAMES[@]}; index++)); do
    url="${GIT_URLS[index]}/${REPOSITORY_NAMES[index]}/archive/${PACKAGE_VERSIONS[index]}.tar.gz"
    tarball="${REPOSITORY_NAMES[index]}-${PACKAGE_VERSIONS[index]}.tar.gz"
    folder="${REPOSITORY_NAMES[index]}-${PACKAGE_VERSIONS[index]}"
    pear_channel=${PEAR_CHANNELS[index]}
    package_tarball="${PACKAGE_NAMES[index]}-${PACKAGE_VERSIONS[index]}.tgz"

    wget "${url}" -O "${tarball}" > /dev/null 2>&1
    tar xzf "${tarball}" > /dev/null 2>&1
    \rm "${tarball}"
    LC_ALL=C sed -i '' "s|${pear_channel}|${NEW_PEAR_CHANNEL}|g" "./${folder}/package.xml"
    pear package "${folder}/package.xml" > /dev/null 2>&1
    \rm -r "${folder}"
    ../vendor/bin/pirum add .. ${package_tarball}
done
popd

rm -rf .gitignore composer.json composer.lock pirum.xml release.sh build/ vendor/
git add --all
git commit -m "Released GitHub pages based on ${CURRENT_BRANCH} branch."
git push --force --set-upstream origin gh-pages
git checkout ${CURRENT_BRANCH}
