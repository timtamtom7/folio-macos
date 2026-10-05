# FOLIO

An RSS reader for macOS with annotation and AI summarisation.

## What it does

- Feeds
- reading queue
- annotations
- tags
- background refresh

## Targets

- macOS

## Structure

Key types:

- ``SQLiteFeedStore``
- ``SummarizationService``
- ``AnnotationPanelView``
- ``TagService``
- ``BackgroundRefreshService``
- ``BackupService``
- ``iCloudSyncService``

Largest of the macOS apps by file count — 99 Swift files. Local SQLite rather than a sync backend.

## Status

Apple-platform experiment built to explore what an AI coding agent could produce for a native app. Not actively maintained.

Xcode projects here were generated with XcodeGen (`project.yml`) unless noted; open the `.xcodeproj` directly.
