"""Ensure an app has the internal TestFlight group "me" (gets every build
automatically) with the operator as a tester. Idempotent: an existing group or
tester is left alone.

Env (from ~/.asc-workspace/env.sh): ASC_ISSUER_ID, ASC_KEY_ID,
ASC_PRIVATE_KEY_PATH, ASC_TESTER_EMAIL. Dry-run unless --apply.

Usage:
  tf_internal_group.py --bundle-id ng.zha.example [--group me] [--apply]
"""
import argparse
import os
import sys
import time

import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com/v1"


def token():
    with open(os.environ["ASC_PRIVATE_KEY_PATH"]) as f:
        key = f.read()
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1200,
         "aud": "appstoreconnect-v1"},
        key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"]})


def call(method, path, params=None, body=None):
    r = requests.request(method, BASE + path, params=params, json=body,
                         headers={"Authorization": f"Bearer {token()}"})
    if r.status_code not in (200, 201, 204):
        sys.exit(f"{method} {path} -> {r.status_code}: {r.text}")
    return r.json() if r.text else {}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle-id", required=True)
    ap.add_argument("--group", default="me")
    ap.add_argument("--email", default=os.environ.get("ASC_TESTER_EMAIL"))
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    if not a.email:
        sys.exit("set ASC_TESTER_EMAIL in ~/.asc-workspace/env.sh or pass --email")

    apps = call("GET", "/apps", {"filter[bundleId]": a.bundle_id})["data"]
    if not apps:
        sys.exit(f"no App Store Connect app for {a.bundle_id}; create the record first")
    app_id = apps[0]["id"]
    print(f"app {app_id} ({apps[0]['attributes']['name']})")

    groups = call("GET", f"/apps/{app_id}/betaGroups")["data"]
    group = next((g for g in groups if g["attributes"]["name"] == a.group
                  and g["attributes"]["isInternalGroup"]), None)
    if group:
        print(f"group '{a.group}' exists ({group['id']})")
    else:
        print(f"{'' if a.apply else '[dry-run] '}POST /betaGroups internal '{a.group}', all builds")
        if not a.apply:
            print(f"[dry-run] POST /betaTesters {a.email} -> '{a.group}'")
            return
        group = call("POST", "/betaGroups", body={"data": {
            "type": "betaGroups",
            "attributes": {"name": a.group, "isInternalGroup": True,
                           "hasAccessToAllBuilds": True},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]

    testers = call("GET", f"/betaGroups/{group['id']}/betaTesters", {"limit": 200})["data"]
    if any((t["attributes"].get("email") or "").lower() == a.email.lower() for t in testers):
        print("tester already in group")
        return
    print(f"{'' if a.apply else '[dry-run] '}POST /betaTesters {a.email} -> '{a.group}'")
    if a.apply:
        call("POST", "/betaTesters", body={"data": {
            "type": "betaTesters", "attributes": {"email": a.email},
            "relationships": {"betaGroups": {"data": [
                {"type": "betaGroups", "id": group["id"]}]}}}})
        print("done")


if __name__ == "__main__":
    main()
