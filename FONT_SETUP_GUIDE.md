# Satoshi Font Setup Guide

## Step 1: Download Satoshi Font

The Satoshi font is available for free from Fontshare.

1. Go to: https://www.fontshare.com/fonts/satoshi
2. Click the **"Get font"** button (or **"Download family"**)
3. This will download a ZIP file called `Satoshi.zip`
4. Unzip the file

## Step 2: Copy Font Files to Project

From the unzipped folder, you'll see multiple font files. We need these variants:

### Required Font Files (TTF or OTF):
- **Satoshi-Regular.ttf** or **Satoshi-Regular.otf**
- **Satoshi-Medium.ttf** or **Satoshi-Medium.otf**
- **Satoshi-Bold.ttf** or **Satoshi-Bold.otf**
- **Satoshi-Black.ttf** or **Satoshi-Black.otf** (optional, for extra bold)

### Where to Copy Them:
Copy these files to:
```
assets/fonts/
```

Your directory should look like:
```
assets/
  fonts/
    Satoshi-Regular.ttf
    Satoshi-Medium.ttf
    Satoshi-Bold.ttf
    Satoshi-Black.ttf
  images/
    ...
```

## Step 3: Continue

Once you've copied the font files, let me know and I'll update the `pubspec.yaml` and `app_theme.dart` files automatically!

## Alternative Fonts (If You Want to Try Others Later)

Since we're setting this up to be easily swappable, here are some great font alternatives:

- **Inter** - https://fonts.google.com/specimen/Inter
- **Poppins** - https://fonts.google.com/specimen/Poppins
- **Work Sans** - https://fonts.google.com/specimen/Work+Sans
- **DM Sans** - https://fonts.google.com/specimen/DM+Sans
- **Plus Jakarta Sans** - https://fonts.google.com/specimen/Plus+Jakarta+Sans

All you'll need to do later is:
1. Download new font files
2. Replace files in `assets/fonts/`
3. Update one line in `app_theme.dart` (fontFamily: 'NewFontName')

