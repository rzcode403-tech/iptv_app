# 📺 IPTV Pro - Flutter Application

A professional IPTV player built with Flutter, featuring a sleek dark cinema UI.

## ✨ Features

- 🎬 **Live TV Streaming** - Play M3U/M3U8 streams with video_player
- 📋 **Playlist Management** - Add, refresh, delete M3U playlists via URL
- ⭐ **Favorites** - Star and quickly access your favorite channels
- 🕐 **Watch History** - Recently watched channels (last 20)
- 🔍 **Search & Filter** - Search by name, filter by group/category
- 📱 **Fullscreen Mode** - Landscape fullscreen with auto-rotation
- 💾 **Persistent Storage** - Playlists and favorites saved locally
- 🌙 **Dark Cinema Theme** - Deep dark UI with cyan accents

## 🏗️ Project Structure

```
lib/
├── main.dart                   # App entry point
├── models/
│   └── channel.dart            # Channel & Playlist models
├── providers/
│   └── iptv_provider.dart      # State management (Provider)
├── screens/
│   ├── main_shell.dart         # Bottom navigation shell
│   ├── home_screen.dart        # Channel list + search/filter
│   ├── player_screen.dart      # Video player
│   ├── favorites_screen.dart   # Starred channels
│   ├── recent_screen.dart      # Watch history
│   └── playlists_screen.dart   # Playlist management
├── widgets/
│   └── channel_card.dart       # Channel list item widget
├── services/
│   └── m3u_parser.dart         # M3U file parser
└── utils/
    └── app_theme.dart          # Colors, fonts, theme
```

## 🚀 Setup

### Prerequisites
- Flutter SDK 3.x
- Android Studio / VS Code
- Android device or emulator (Android 5.0+)

### Install & Run

```bash
# Clone or extract the project
cd iptv_pro

# Install dependencies
flutter pub get

# Run on device
flutter run

# Build APK
flutter build apk --release
```

### Android Permissions
The app requires in `AndroidManifest.xml`:
- `INTERNET` - For streaming and loading playlists
- `ACCESS_NETWORK_STATE` - Connection monitoring
- `usesCleartextTraffic="true"` - For HTTP streams

## 📱 How to Use

1. **Launch app** → Tap "Try Demo Playlist" or go to Playlists tab
2. **Add playlist** → Playlists tab → "+ Add M3U Playlist" → Enter name + URL
3. **Watch channel** → Tap any channel in Live TV tab
4. **Favorite** → Tap ⭐ on any channel card
5. **Filter** → Use category chips below search bar
6. **Fullscreen** → Tap fullscreen button in player controls

## 🎨 UI Design

- **Background**: #080C14 (deep space)
- **Primary**: #00D4FF (electric cyan)
- **Accent**: #FF6B35 (ember orange)
- **Font**: Be Vietnam Pro (Google Fonts)
- **Live badge**: Red dot indicator

## 📦 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| video_player | ^2.8.1 | Video streaming |
| chewie | ^1.7.4 | Player controls UI |
| provider | ^6.1.1 | State management |
| shared_preferences | ^2.2.2 | Local storage |
| cached_network_image | ^3.3.0 | Channel logo caching |
| google_fonts | ^6.1.0 | Be Vietnam Pro font |
| shimmer | ^3.0.0 | Loading skeletons |
| http | ^1.1.0 | M3U playlist fetching |

## 🔧 Customization

### Add More Features
- **EPG Support**: Parse XMLTV format and show program guide
- **PiP Mode**: Picture-in-picture on Android 8+
- **Download**: Record streams locally
- **VLC Player**: Use flutter_vlc_player for better codec support
- **Chromecast**: Add cast support with flutter_cast_framework

### Change Theme
Edit `lib/utils/app_theme.dart` to customize colors, fonts, and styles.

## 📝 M3U Format Support

```
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-logo="https://logo.url" group-title="News",Channel Name
https://stream.url/live.m3u8
```

Supported attributes:
- `tvg-id` - EPG channel ID
- `tvg-logo` - Channel logo URL
- `group-title` - Category/group name
- Channel name after the comma
# iptv_app
