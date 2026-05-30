#!/bin/bash

# Load secret from .env
source .env

# Run Flutter build with the secret
flutter build ios --release --dart-define=ACCESS_TOKEN=$ACCESS_TOKEN