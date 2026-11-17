
#!/bin/bash
set -e

echo "Creating .env file from Vercel environment variables..."

cat > .env <<EOF
RESEND_API_KEY=$RESEND_API_KEY
FROM_EMAIL=$FROM_EMAIL
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

echo ".env file created successfully."

echo "Installing Flutter 3.41.2..."

# Remove any previously cached Flutter SDK to avoid using the wrong version.
rm -rf /tmp/flutter

git clone --depth 1 --branch 3.41.2 \
  https://github.com/flutter/flutter.git /tmp/flutter

export PATH="/tmp/flutter/bin:$PATH"

echo "Flutter version:"
flutter --version

echo "Getting Flutter dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release --no-wasm-dry-run

echo "Flutter Web build completed successfully."

if [ ! -f "build/web/index.html" ]; then
  echo "ERROR: Flutter web index.html was not generated."
  exit 1
fi

echo "Verified build/web/index.html exists."
