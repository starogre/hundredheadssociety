# Phosphor Icons Implementation Guide

## ✅ What Was Implemented

### Package Added:
- **phosphor_flutter v2.1.0** - Modern duotone icon library with 6000+ icons

### Centralized Icon System:
Created `AppIcons` helper class in `lib/theme/app_theme.dart` for easy icon management.

### Icons Replaced in Dashboard:

#### Bottom Navigation (with duotone on active):
- **My Heads**: `squaresFour` (grid icon)
- **Community**: `users` (people icon)  
- **Profile**: `user` (person icon)
- **Weekly Sessions**: `calendar` (calendar icon)

#### Other Icons:
- **Settings**: `gear` icon
- **Add Photo FAB**: `camera` icon (bold style)
- **Error States**: `warningCircle` icon

## 🎨 Duotone Effect

The icons now have a beautiful two-tone effect:
- **Inactive**: Single color (regular style)
- **Active**: Duotone with primary + secondary color (30% opacity)

## 📖 How to Use Phosphor Icons

### Method 1: Using AppIcons Helper (Recommended)

```dart
// Duotone icon with app colors
AppIcons.duotone(
  PhosphorIconsDuotone.house,
  size: 24,
)

// Custom colors
AppIcons.duotone(
  PhosphorIconsDuotone.heart,
  primaryColor: Colors.red,
  secondaryColor: Colors.pink.withOpacity(0.3),
)

// Single-color icon
AppIcons.regular(
  PhosphorIconsRegular.star,
  color: AppColors.rustyOrange,
)
```

### Method 2: Direct Usage

```dart
// Regular style
PhosphorIcon(
  PhosphorIconsRegular.heart,
  color: AppColors.forestGreen,
  size: 24,
)

// Duotone style
PhosphorIcon(
  PhosphorIconsDuotone.heart,
  color: AppColors.forestGreen,
  duotoneSecondaryColor: AppColors.rustyOrange.withOpacity(0.3),
  size: 24,
)

// Bold style
PhosphorIcon(
  PhosphorIconsBold.star,
  color: AppColors.rustyOrange,
)
```

## 🔍 Available Icon Styles

Phosphor provides multiple weights for each icon:
- `PhosphorIconsRegular` - Default weight
- `PhosphorIconsThin` - Thin lines
- `PhosphorIconsLight` - Light weight
- `PhosphorIconsBold` - Bold/thick lines
- `PhosphorIconsFill` - Filled solid
- `PhosphorIconsDuotone` - Two-tone effect ⭐

## 📚 Finding Icons

Browse all 6000+ icons at: https://phosphoricons.com

Popular icons for your app:
- **Navigation**: `house`, `users`, `user`, `calendar`, `gear`
- **Actions**: `camera`, `plus`, `trash`, `pencil`, `check`
- **Media**: `image`, `imageSquare`, `camera`, `upload`
- **Communication**: `chatCircle`, `bell`, `envelope`, `heart`
- **Status**: `checkCircle`, `warningCircle`, `xCircle`, `info`
- **Social**: `instagramLogo`, `twitterLogo`, `facebookLogo`

## 🎯 Testing Checklist

Run the app and check:

### Bottom Navigation:
- [ ] Icons appear correctly
- [ ] Active tab shows duotone effect
- [ ] Inactive tabs show regular style
- [ ] Icons are properly sized and aligned

### Dashboard:
- [ ] Settings gear icon appears in app bar
- [ ] FAB camera icon is visible and styled
- [ ] Error states show warning circle icon

### Visual Quality:
- [ ] Icons are crisp and clear
- [ ] Duotone colors match app theme
- [ ] Icons scale properly on different devices

## 🔧 Customization

### Change Default Icon Style:
Edit `lib/theme/app_theme.dart`:

```dart
class AppIcons {
  // Change this to use a different default style
  static const PhosphorIconsStyle defaultStyle = PhosphorIconsStyle.duotone;
}
```

### Change Default Colors:
Edit the `duotone()` method in `AppIcons`:

```dart
static PhosphorIcon duotone(...) {
  return PhosphorIcon(
    icon,
    color: primaryColor ?? AppColors.forestGreen, // Change primary
    duotoneSecondaryColor: secondaryColor ?? AppColors.rustyOrange.withOpacity(0.3), // Change secondary
  );
}
```

## 🚀 Next Steps

### More Icons to Replace:
You can continue replacing Material Icons throughout the app:

1. **Settings Screen** - Replace list item icons
2. **Profile Screen** - Replace action icons
3. **Add Portrait Screen** - Replace camera/gallery icons
4. **Community Screen** - Replace filter/sort icons
5. **Weekly Sessions** - Replace RSVP icons

### Example Replacements:
```dart
// Old
Icon(Icons.edit)

// New
PhosphorIcon(PhosphorIconsRegular.pencil)

// Old
Icon(Icons.delete)

// New
PhosphorIcon(PhosphorIconsRegular.trash)

// Old
Icon(Icons.favorite)

// New
PhosphorIcon(PhosphorIconsDuotone.heart)
```

## 📝 Notes

- Phosphor icons are **vector-based** (scalable without quality loss)
- **Lightweight** - only includes icons you use
- **Consistent design** - all icons share the same design language
- **Well-maintained** - actively developed open-source project

## 🐛 Troubleshooting

**Issue**: Icons not showing
- **Fix**: Hot restart the app (R), not just hot reload (r)

**Issue**: Duotone colors not working
- **Fix**: Make sure you're using `PhosphorIconsDuotone.iconName` and setting `duotoneSecondaryColor`

**Issue**: Icons look pixelated
- **Fix**: They shouldn't! They're vectors. Make sure you're using the latest phosphor_flutter version.

