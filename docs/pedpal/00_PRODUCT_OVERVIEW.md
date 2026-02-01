# PED Pal — Product Overview

## Purpose
PED Pal is an iOS app for tracking medication protocols, administrations (including injections), vitals, and personal observations with:
- Calendar-first UX for schedule clarity
- Reminder notifications
- Per-day timeline view
- Vitals + notes tracking
- Graphs:
  1) Estimated serum levels per drug (formulas pluggable later)
  2) Vitals over time with protocol start/end markers

> This app does not recommend or prescribe medications or dosages. Users enter their own schedule data.

## Target platform
- iOS 17+ (SwiftUI)
- Local-first storage (SwiftData), optional CloudKit sync later
- Notifications via UserNotifications

## Core concepts
- Protocol: a named plan that contains one or more Drugs with schedules & timelines
- Drug: medication configuration (name, half-life, route, unit, color)
- DoseEvent: one administration instance (scheduled time + optional completion time)
- VitalsEntry: weight, BP, RHR, blood glucose
- DailyLog: side effects + observations (free text)
- InjectionSite: optional for injected DoseEvent

## Non-goals (v1)
- No clinician portal, no social sharing
- No dosing calculator / optimization recommendations
- No medical warnings beyond basic safety copy
