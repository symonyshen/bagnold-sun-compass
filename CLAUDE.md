# Bagnold Sun Compass

## What this app is
A Flutter app (iOS first, Android later) that digitally replicates the mechanics of a Bagnold Sun Compass — a WWII-era desert navigation tool.

The user sets their desired heading on a dial. The app calculates where the sun is (from coords + device time) and draws a target shadow line on screen. The user then holds their phone flat, places a vertical object (finger/stick) on the screen, and rotates the phone until the physical shadow aligns with the target line — that's the direction to walk.

## Shadow casting approach
Dial-based UI. The user manually rotates a dial to set their desired heading. No accelerometer or AR — purely visual alignment of a physical shadow with a line drawn on screen.

## Navigation without GPS (current: Option A)
GPS is optional. The user can enter coordinates manually (e.g. read from Google Maps offline). On the compass screen, a timer shows elapsed time since last coord update, reminding the user to re-enter coords at checkpoints.

**Planned: Option C (dead reckoning)**
- User inputs speed (km/h or mph)
- App uses heading (from dial) + speed + elapsed time to estimate current position continuously
- User can override with manual coords at any checkpoint (resets dead reckoning origin)

## Platform
Flutter (Dart). Single codebase for iOS + Android. iOS is the primary target.

## Project structure
```
lib/
  main.dart
  screens/
    location_screen.dart     # Manual lat/lng input + optional "Use GPS" button
    compass_screen.dart      # Main dial + shadow indicator + coord staleness timer
  widgets/
    dial_widget.dart         # Rotatable heading dial
    shadow_indicator.dart    # Target shadow line rendered on screen
  services/
    location_service.dart    # Tries GPS, returns null if unavailable
    sun_calculator.dart      # Sun azimuth/altitude from coords + datetime (NOAA algorithm)
  models/
    sun_position.dart        # Azimuth, altitude
    app_state.dart           # Current coords, heading, sun position, last update time
```

## Core logic
```
Coords (manual or GPS) + Device time
    ↓
sun_calculator → SunPosition (azimuth, altitude)
    ↓
User rotates dial → desired heading (degrees)
    ↓
shadow_angle = desired_heading - sun_azimuth
    ↓
shadow_indicator draws target line at shadow_angle
    ↓
User physically aligns shadow with line → walk that direction
```

## Key decisions
- No network dependency at runtime — coords + device clock only
- No offline map in-app — user gets coords externally (Google Maps, paper map)
- Sun position math: NOAA solar calculator algorithm implemented in Dart
- Dead reckoning (Option C) is the planned next milestone after Option A ships
