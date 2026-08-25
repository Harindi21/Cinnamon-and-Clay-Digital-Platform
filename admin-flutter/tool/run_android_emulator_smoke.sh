#!/usr/bin/env bash
set -Eeuo pipefail

readonly DEVICE_ID="${ANDROID_SERIAL:-emulator-5554}"
readonly PACKAGE_ID="dev.cinnamonandclay.admin"
readonly APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

print_diagnostics() {
  local status="${1:-$?}"
  trap - ERR

  echo "::group::Android emulator diagnostics"
  echo "Smoke command failed with exit code ${status}."
  echo "Device: ${DEVICE_ID}"
  adb -s "${DEVICE_ID}" shell getprop ro.build.version.release 2>/dev/null || true
  adb -s "${DEVICE_ID}" shell getprop ro.build.version.sdk 2>/dev/null || true
  adb -s "${DEVICE_ID}" shell pidof "${PACKAGE_ID}" 2>/dev/null || true
  adb -s "${DEVICE_ID}" logcat -d -t 250 2>/dev/null || true
  echo "::endgroup::"

  exit "${status}"
}
trap 'print_diagnostics $?' ERR

fail() {
  echo "$1" >&2
  print_diagnostics 1
}

adb -s "${DEVICE_ID}" wait-for-device

# Keep the integration-test invocation in this repository script rather than in
# android-emulator-runner's multiline `script:` input. That action executes each
# input line as an independent `sh -c`, so shell continuation backslashes in the
# workflow become literal Flutter arguments and `cd` does not persist.
flutter test integration_test/app_smoke_test.dart \
  -d "${DEVICE_ID}" \
  --dart-define=APP_ENVIRONMENT=local \
  --dart-define=API_BASE_URL=http://localhost:8082 \
  --dart-define=OIDC_ISSUER_URL=http://localhost:8081/realms/cinnamon-clay \
  --dart-define=OIDC_CLIENT_ID=cinnamon-clay-admin-mobile \
  --dart-define=OIDC_ALLOW_INSECURE=true

if [[ ! -f "${APK_PATH}" ]]; then
  fail "Expected debug APK was not produced at ${APK_PATH}."
fi

adb -s "${DEVICE_ID}" install -r "${APK_PATH}"
adb -s "${DEVICE_ID}" shell am start -W -n "${PACKAGE_ID}/.MainActivity"

pid="$(adb -s "${DEVICE_ID}" shell pidof "${PACKAGE_ID}" | tr -d '\r')"
if [[ -z "${pid}" ]]; then
  fail "${PACKAGE_ID} did not remain running after launch."
fi
echo "${PACKAGE_ID} is running with pid ${pid}."

callback="$(
  adb -s "${DEVICE_ID}" shell cmd package resolve-activity --brief \
    -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE \
    -d 'dev.cinnamonandclay.admin:/oauthredirect' \
    | tr -d '\r'
)"
echo "OIDC callback resolves to: ${callback}"
grep -Fq 'net.openid.appauth.RedirectUriReceiverActivity' <<<"${callback}"
