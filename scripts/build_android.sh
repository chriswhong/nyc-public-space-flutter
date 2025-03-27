#!/bin/bash

# Load secret from .env
source .env

flutter clean

# Run Flutter build with the secret
flutter build appbundle --release --dart-define ACCESS_TOKEN=$ACCESS_TOKEN